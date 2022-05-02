import 'dart:io';

import 'package:dart_bom/dart_bom.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:test/test.dart';

void main() {
  test('Empty replace dependencies', () async {
    final files = await setupPubspecFiles(
        source: PubSpec(), target: PubSpec(), prefix: 'empty');

    final result = await files.execute();
    expect(result.mismatches, isEmpty);
    expect(result.matches, isEmpty);
    expect(result.skipped, isEmpty);
  });

  test('Simple replace dependencies', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(dependencies: {
          'path': HostedReference(Version.parse('1.3.0')),
        }),
        prefix: 'simple');

    final result = await files.execute();
    expect(result.mismatches, isNotEmpty);
    expect(result.mismatches.first.package, equals('path'));
    expect(result.targetPubspec.dependencies['path']!, finalVersion);
    expect(result.skipped, isEmpty);
  });

  test('Skip path dependencies', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(dependencies: {
          'path': PathReference('path/to/local'),
        }),
        prefix: 'simple');

    final result = await files.execute();
    expect(result.mismatches, isEmpty);
    expect(result.skipped, isNotEmpty);
    expect(result.skipped.first.package, equals('path'));
    expect(result.targetPubspec.dependencies['path']!,
        PathReference('path/to/local'));
  });

  test('Skip dependency_overrides by default', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(dependencyOverrides: {
          'path': HostedReference(Version.parse('1.4.0')),
        }),
        prefix: 'simple');

    final result = await files.execute();
    expect(result.mismatches, isEmpty);
    expect(result.skipped, isNotEmpty);
    expect(result.skipped.first.package, equals('path'));
    expect(result.targetPubspec.dependencyOverrides['path']!,
        HostedReference(Version.parse('1.4.0')));
  });

  test('Force override skip path dependencies', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(dependencies: {
          'path': PathReference('path/to/local'),
        }),
        prefix: 'simple');

    final result = await files.execute(overwritePathDependencies: true);
    expect(result.mismatches, isNotEmpty);
    expect(result.mismatches.first.package, equals('path'));
    expect(result.targetPubspec.dependencies['path']!, finalVersion);
    expect(result.skipped, isEmpty);
  });

  test('Force override dependency_overrides', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(dependencyOverrides: {
          'path': HostedReference(Version.parse('1.4.0')),
        }),
        prefix: 'override');

    final result = await files.execute(overwriteDependencyOverrides: true);
    expect(result.mismatches, isNotEmpty);
    expect(result.mismatches.first.package, equals('path'));
    expect(result.targetPubspec.dependencyOverrides['path']!, finalVersion);
    expect(result.skipped, isEmpty);
  });

  test('Invalid source file', () async {
    final files = PubSetup(File('nonexist'), File('nonexist'));
    expect(() => files.execute(),
        throwsA(isA<DartBomException>().withExitCode(2)));
  });
}

Future<PubSetup> setupPubspecFiles(
    {String prefix = 'test',
    required PubSpec source,
    required PubSpec target}) async {
  source = source.copy(name: 'bom_$prefix');
  target = target.copy(name: prefix);
  var sourceBom = File('./.$prefix-bom-pubspec.yaml');
  if (sourceBom.existsSync()) sourceBom.deleteSync();
  var targetBom = File('./.$prefix-pubspec.yaml');
  if (targetBom.existsSync()) targetBom.deleteSync();

  await source.writeToFile(sourceBom);
  await target.writeToFile(targetBom);
  return PubSetup(sourceBom, targetBom);
}

class PubSetup {
  final File sourceFile;
  final File targetFile;

  PubSetup(this.sourceFile, this.targetFile);

  Future<DartBomResult> execute({
    bool writeFiles = false,
    bool overwritePathDependencies = false,
    bool overwriteDependencyOverrides = false,
  }) {
    var args = DartBomOptions(
      source: sourceFile.absolute.path,
      target: targetFile.absolute.path,
      writeFiles: writeFiles,
      overwriteDependencyOverrides: overwriteDependencyOverrides,
      overwritePathDependencies: overwritePathDependencies,
    );
    print('Running syncPubSpecFiles ${args}');

    return syncPubspecFiles(args);
  }
}

extension on TypeMatcher<DartBomException> {
  TypeMatcher<DartBomException> withExitCode(int code) {
    return having((p0) => p0.exitCode, 'exitCode', equals(code));
  }
}
