import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_bom/dart_bom.dart';

Future main(List<String> arguments) async {
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

  var args = argParser.parse(arguments);

  if (args['help'] == true) {
    print(argParser.usage);
    exit(1);
  }

  if (args['source'] == null) {
    exit(1);
  }

  try {
    var result = await syncPubspecFiles(DartBomOptions(
        source: args.get('source'),
        target: args.get('target'),
        writeFiles: args.get('write'),
        backupFiles: args.get('no-backed') != true,
        overwritePathDependencies: args.get('overwrite-path'),
        overwriteDependencyOverrides: args.get('overwrite-overrides')));
    var mismatches = result.mismatches;
    var skipped = result.skipped;
    var matches = result.matches;
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
  } catch (e, stack) {
    if (e is DartBomException) {
      print(e.message);
      exit(e.exitCode);
    } else {
      print("Unknown error $e");
      print(stack);
      exit(9);
    }
  }
}

extension on ArgResults {
  T get<T>(String key, [T? defaultValue]) {
    return (this[key] as T? ?? defaultValue!);
  }
}
