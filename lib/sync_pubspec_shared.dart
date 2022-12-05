import 'dart:io';

import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/common/pubspec_ext.dart';
import 'package:pubspec/pubspec.dart';

import 'dart_bom.dart';

Future<DartBomResult> syncPubspecData(
  PubSpec sourcePubspec,
  PubSpec targetSpec, {
  PubSpec? overrideSpec,
  required DartBomOptions options,
  required CliLogger logger,
}) async {
  final output = targetSpec;

  var allDependencies = <String, DependencyReference>{
    ...sourcePubspec.dependencies,
    ...sourcePubspec.devDependencies,
    ...sourcePubspec.dependencyOverrides,
  };

  void addPathDependency(
      DependencyLocation location, String name, DependencyReference ref) {
    if (overrideSpec != null) {
      overrideSpec.dependencyOverrides[name] = ref;
    } else {
      targetSpec.getDependencies(location)[name] = ref;
    }
  }

  var mismatches = <DependencyMismatch>[];
  var hasPathChanges = false;
  var skipped = <DependencyMismatch>[];
  var matches = <DependencyMismatch>[];
  ({
    DependencyLocation.dependencies: output.dependencies,
    DependencyLocation.devDependencies: output.devDependencies,
    DependencyLocation.dependencyOverrides: output.dependencyOverrides,
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
                'Not overwriting hasPathChanges dependencies.  Use --overwrite-hasPathChanges to force this behavior');
        } else if (type == DependencyLocation.dependencyOverrides &&
            !options.overwriteDependencyOverrides) {
          skipped.add(result
            ..reason =
                'Not overwriting dependency_overrides section:  Use --overwrite-overwrites to force this behavior');
        } else {
          if (currentDependency is PathReference) {
            addPathDependency(type, packageName, fromBom);
            hasPathChanges = true;
          } else {
            depCollection[packageName] = fromBom;
          }
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
      targetPubspec: output,
      sourceFile: options.source,
      targetFile: options.target);

  if (options.writeFiles) {
    if (!mismatches.isEmpty) {
      if (options.backupFiles) {
        logger.log(
            'Making backup of target file: .${options.source}.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
        File(options.target).copySync(
            '.${options.source}.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
      }

      await output.writeTo(options.target);
    }

    if (hasPathChanges && overrideSpec != null) {
      logger.log('Writing pubspec_overrides.dart');
      var overridePath =
          File(options.target).sibling("pubspec_overrides.dart").absolute.path;
      await overrideSpec.writeTo(overridePath);
    }
  }

  return bomResult;
}
