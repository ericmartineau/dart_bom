import 'dart:io';

import 'package:pubspec/pubspec.dart';

import 'dart_bom.dart';

Future<DartBomResult> syncPubspecFiles(
    [DartBomOptions options = const DartBomOptions()]) async {
  late PubSpec sourcePubspec;
  late PubSpec targetPubspec;

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

  var allDependencies = <String, DependencyReference>{
    ...sourcePubspec.dependencies,
    ...sourcePubspec.devDependencies,
    ...sourcePubspec.dependencyOverrides,
  };

  var mismatches = <DependencyMismatch>[];
  var skipped = <DependencyMismatch>[];
  var matches = <DependencyMismatch>[];
  ({
    DependencyLocation.dependencies: targetPubspec.dependencies,
    DependencyLocation.devDependencies: targetPubspec.devDependencies,
    DependencyLocation.dependencyOverrides: targetPubspec.dependencyOverrides,
  }).forEach((type, depCollection) {
    depCollection.forEach((packageName, currentDependency) {
      var fromBom = allDependencies[packageName];

      if (fromBom != null) {
        var result = DependencyMismatch(
          type,
          currentDependency,
          fromBom,
          packageName,
        );
        if (fromBom == currentDependency) {
          matches.add(result);
        } else if (currentDependency is PathReference &&
            !options.overwritePathDependencies) {
          skipped.add(result
            ..reason =
                'Not overwriting path dependencies.  Use --overwrite-path to force this behavior');
        } else if (type == DependencyLocation.dependencyOverrides &&
            !options.overwriteDependencyOverrides) {
          skipped.add(result
            ..reason =
                'Not overwriting dependency_overrides section:  Use --overwrite-overwrites to force this behavior');
        } else {
          depCollection[packageName] = fromBom;
          mismatches.add(result);
        }
      }
    });
  });

  var bomResult = DartBomResult(
      mismatches: mismatches,
      matches: matches,
      skipped: skipped,
      sourcePubspec: sourcePubspec,
      targetPubspec: targetPubspec,
      sourceFile: options.source,
      targetFile: options.target);

  if (options.writeFiles) {
    if (mismatches.isEmpty) {
      return bomResult;
    }
    if (options.backupFiles) {
      print(
          'Making backup of target file: .${options.source}.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
      File(options.target).copySync(
          '.${options.source}.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
    }

    await targetPubspec.writeTo(options.target);
  }

  return bomResult;
}
