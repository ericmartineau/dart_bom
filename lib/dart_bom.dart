library dart_bom;

import 'dart:io';

import 'package:args/args.dart';
import 'package:pubspec/pubspec.dart';

Future syncPubspecFiles([List<String> arguments = const []]) async {
  final ArgParser argParser = ArgParser();

  argParser.addOption("source", abbr: "s");
  argParser.addOption("target", abbr: "t", defaultsTo: './pubspec.yaml');
  argParser.addFlag("write", abbr: "w");
  argParser.addFlag("no-backup", abbr: "b");
  argParser.addFlag("overwrite-path",
      abbr: "p",
      help: 'Overwrites path dependencies.  By default, this is off',
      defaultsTo: false);
  argParser.addFlag("overwrite-overrides",
      abbr: "o",
      help:
          'Overwrites dependency_override dependencies.  By default, this is off',
      defaultsTo: false);

  argParser.addFlag("help", abbr: 'h');

  var result = argParser.parse(arguments);

  if (result['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  if (result['source'] == null) {
    print('You must provide a source pubspec.yaml file');
    print(argParser.toString());
    exit(1);
  }

  var target = result['target'] as String;
  var sourceFileName = result['source'] as String;
  late PubSpec sourcePubspec;
  late PubSpec targetPubspec;

  try {
    var loadFile = PubSpec.loadFile(sourceFileName);
    sourcePubspec = await loadFile;
  } catch (e) {
    print('ERROR: Unable to parse $sourceFileName as a pubspec.yaml: $e');
    exit(2);
  }
  try {
    targetPubspec = await PubSpec.loadFile(target);
  } catch (e) {
    print('ERROR: Unable to parse target $target as a pubspec.yaml: $e');
    exit(2);
  }

  var allDependencies = <String, DependencyReference>{
    ...sourcePubspec.dependencies,
    ...sourcePubspec.devDependencies,
    ...sourcePubspec.dependencyOverrides,
  };

  var overwritePath = result['overwrite-path'] as bool? ?? false;
  var overwriteOverrides = result['overwrite-overrides'] as bool? ?? false;

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
        } else if (currentDependency is PathReference && !overwritePath) {
          skipped.add(result
            ..reason =
                'Not overwriting path dependencies.  Use --overwrite-path to force this behavior');
        } else if (type == DependencyLocation.dependencyOverrides &&
            !overwriteOverrides) {
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

  print("RESULTS OF DART_BOM:");
  if (mismatches.isNotEmpty) {
    print("  NEEDS UPDATE: ");

    mismatches.forEach((value) {
      print('    ${value.location}[${value.package}]:');
      print('      original: ${value.original}');
      print('      bom: ${value.fromBom}');
    });
  }
  if (skipped.isNotEmpty) {
    print("  SKIPPED: ");
    skipped.forEach((value) {
      print('    ${value.location.value}[${value.package}]: ${value.reason}');
    });
  }
  if (matches.isNotEmpty) {
    print("  MATCHES: ${matches.map((e) => e.package).join(', ')}");
  }

  var write = result['write'] as bool? ?? false;
  if (write) {
    if (mismatches.isEmpty) {
      print('No changes to update.  Leaving files as they are');
      exit(0);
    }
    if (result['no-backup'] != true) {
      print(
          'Making backup of target file: .$sourceFileName.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
      // Copy the source file
      File(target).copySync(
          '.$sourceFileName.${DateTime.now().millisecondsSinceEpoch / 1000}.bak');
    }

    final ioSink = File(target).openWrite();
    try {
      YamlToString().writeYamlString(targetPubspec.toJson(), ioSink);
    } finally {
      print('Updated $target from bom');
      return ioSink.close();
    }
  }

  exit(0);
}

enum DependencyLocation { dependencies, devDependencies, dependencyOverrides }

class DependencyMismatch {
  final DependencyLocation location;
  final DependencyReference original;
  final DependencyReference fromBom;
  final String package;
  String? reason;

  DependencyMismatch(
    this.location,
    this.original,
    this.fromBom,
    this.package, [
    this.reason,
  ]);
}

extension on DependencyLocation {
  String get value {
    return "$this".replaceAll('DependencyLocation.', '');
  }
}
