import 'dart:io';

import 'package:dart_bom/common/pubspec_ext.dart';
import 'package:dart_bom/sync_pubspec_shared.dart';
import 'package:pubspec/pubspec.dart';

import 'common/logging.dart';
import 'dart_bom.dart';

Future<DartBomResult> syncPubspecOverrideFiles(CliLogger logger,
    [DartBomOptions options = const DartBomOptions()]) async {
  late PubSpec sourcePubspec;
  late PubSpec targetPubspec;
  late PubSpec overridePubspec;

  try {
    var loadFile = PubSpec.loadFile(options.source);
    sourcePubspec = await loadFile;
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse ${options.source} as a pubspec.yaml: $e', 2);
  }
  try {
    targetPubspec = await PubSpec.loadFile(options.target);
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse target ${options.target} as a pubspec.yaml: $e',
        2);
  }
  final overridePubspecFile =
      File(options.target).sibling("pubspec_overrides.yaml");
  try {
    overridePubspec = overridePubspecFile.existsSync()
        ? targetPubspec.merge(
            await PubSpec.loadFile(overridePubspecFile.absolute.path),
          )
        : PubSpec(
            dependencyOverrides: {
              ...targetPubspec.dependencies,
              ...targetPubspec.devDependencies,
              ...targetPubspec.dependencyOverrides,
            },
          );
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse target ${options.target} as a pubspec.yaml: $e',
        2);
  }

  final bomResult = syncPubspecData(
    sourcePubspec,
    targetPubspec,
    overrideSpec: overridePubspec,
    logger: logger,
    options: options.copyWith(
      useOverrideFile: true,
      overwriteDependencyOverrides: true,
      overwritePathDependencies: true,
      target: overridePubspecFile.absolute.path,
    ),
  );
  return bomResult;
}
