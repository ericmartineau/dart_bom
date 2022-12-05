import 'dart:io';

import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:test/test.dart';

void main() {
  test('Empty replace dependencies', () async {
    final files = await setupPubspecFiles(
        source: PubSpec(), target: PubSpec(), prefix: 'empty');

    final result = await files.executeSyncBom();
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

    final result = await files.executeSyncBom();
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

    final result = await files.executeSyncBom();
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

    final result = await files.executeSyncBom();
    expect(result.mismatches, isEmpty);
    expect(result.skipped, isNotEmpty);
    expect(result.skipped.first.package, equals('path'));
    expect(result.targetPubspec.dependencyOverrides['path']!,
        HostedReference(Version.parse('1.4.0')));
  });

  test('Test get my dependency with publish_to', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(
            version: Version.parse('0.2.3'),
            publishTo: Uri.parse('https://myspecialpubserver.com'),
            dependencies: {
              'path': finalVersion,
            }),
        target: PubSpec(),
        prefix: 'simple');

    final result = await files.executePrintMyVersion();
    expect(
        result,
        equals(
          "  bom_simple:\n    hosted: https://myspecialpubserver.com\n    version: ^0.2.3\n",
        ));
  });

  test('Test get my dependency without publish_to', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(version: Version.parse('0.2.3'), dependencies: {
          'path': finalVersion,
        }),
        target: PubSpec(),
        prefix: 'simple');

    final result = await files.executePrintMyVersion();
    expect(
        result,
        equals(
          "  bom_simple: ^0.2.3\n",
        ));
  });

  test('Test get my dependency with null version', () async {
    final files = await setupPubspecFiles(
        source: PubSpec(dependencies: {}), target: PubSpec(), prefix: 'simple');

    final result = await files.executePrintMyVersion();
    expect(
        result,
        equals(
          "  bom_simple:\n    path: /Users/ericm/sunny/local_plugins/dart_bom/.\n",
        ));
  });

  test('Test get my dependency where publish_to == none', () async {
    var finalVersion = HostedReference(Version.parse('1.2.0'));
    final files = await setupPubspecFiles(
        source: PubSpec(
            version: Version.parse('0.2.3'),
            publishTo: Uri.parse('none'),
            dependencies: {
              'path': finalVersion,
            }),
        target: PubSpec(),
        prefix: 'simple');

    final result = await files.executePrintMyVersion();
    expect(
        result,
        equals(
          "  bom_simple:\n    path: /Users/ericm/sunny/local_plugins/dart_bom/.\n",
        ));
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

    final result = await files.executeSyncBom(overwritePathDependencies: true);
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

    final result =
        await files.executeSyncBom(overwriteDependencyOverrides: true);
    expect(result.mismatches, isNotEmpty);
    expect(result.mismatches.first.package, equals('path'));
    expect(result.targetPubspec.dependencyOverrides['path']!, finalVersion);
    expect(result.skipped, isEmpty);
  });

  test('Invalid source file', () async {
    final files = PubSetup(File('nonexist'), File('nonexist'));
    expect(() => files.executeSyncBom(),
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

  Future<String> executePrintMyVersion() {
    return getMyVersion(
        DartVersionOptions(source: this.sourceFile.absolute.path));
  }

  Future<DartBomResult> executeSyncBom({
    CliLogger? logger,
    bool writeFiles = false,
    bool overwritePathDependencies = false,
    bool overwriteDependencyOverrides = false,
  }) {
    logger ??= CliLogger();
    var args = DartBomOptions(
      source: sourceFile.absolute.path,
      target: targetFile.absolute.path,
      writeFiles: writeFiles,
      overwriteDependencyOverrides: overwriteDependencyOverrides,
      overwritePathDependencies: overwritePathDependencies,
    );
    print('Running syncPubSpecFiles ${args}');

    return syncPubspecFiles(logger, args);
  }
}

extension on TypeMatcher<DartBomException> {
  TypeMatcher<DartBomException> withExitCode(int code) {
    return having((p0) => p0.exitCode, 'exitCode', equals(code));
  }
}
