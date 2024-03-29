import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/sync_pubspec_override_files.dart';

Future main(List<String> arguments) {
  final ArgParser argParser = ArgParser();

  argParser.addOption("source", abbr: "s", help: 'The path to the source file');
  argParser.addOption("target",
      abbr: "t",
      defaultsTo: './pubspec.yaml',
      help: 'The path to the target file');
  argParser.addFlag("override",
      abbr: "r",
      help: 'Whether to write to pubspec_overrides.yaml in the same folder');
  argParser.addFlag("write",
      abbr: "w", defaultsTo: false, help: 'Whether to write the files');
  argParser.addFlag("no-backup",
      abbr: "b", defaultsTo: false, help: 'Skip backing up target files');
  argParser.addFlag("overwrite-path",
      abbr: "p",
      help: 'Overwrites path dependencies.  By default, this is off',
      defaultsTo: false);
  argParser.addFlag("overwrite-overrides",
      abbr: "o",
      help:
          'Overwrites dependency_override dependencies.  By default, this is off',
      defaultsTo: false);
  argParser.addFlag("verbose",
      abbr: "v", help: 'Enabled verbose logging', defaultsTo: false);
  argParser.addFlag("help", abbr: 'h');

  var args = argParser.parse(arguments);

  if (args['help'] == true) {
    print(argParser.usage);
    exit(1);
  }

  if (args['source'] == null) {
    print('You must provide a source file');
    exit(1);
  }

  var options = DartBomOptions(
      source: args.get('source'),
      target: args.get('target'),
      writeFiles: args.get('write'),
      backupFiles: args.get('no-backup') != true,
      overwritePathDependencies: args.get('overwrite-path'),
      overwriteDependencyOverrides: args.get('overwrite-overrides'));

  if (!File(options.target).existsSync()) {
    print('The destination file pubspec.yaml does not exist');
    exit(1);
  }

  var logger = CliLogger.of(verbose: args["verbose"] == true);
  final future = args['override'] == true
      ? syncPubspecFiles(logger, options)
      : syncPubspecOverrideFiles(logger, options);
  return future.catchError((e, stack) {
    if (e is DartBomException) {
      print(e.message);
      exit(e.exitCode);
    } else {
      print("Unknown error $e");
      print(stack);
      exit(9);
    }
  }).then((result) {
    var mismatches = result.mismatches;
    var skipped = result.skipped;
    if (mismatches.isNotEmpty) {
      mismatches.forEach((value) {
        print(
            'mismatch: ${value.location.value}[${value.package}]: ${value.original} -> ${value.fromBom}'
                .replaceAll('\n', ' '));
      });
    }
    if (skipped.isNotEmpty) {
      skipped.forEach((value) {
        print(
            'skipped: ${value.location.value}[${value.package}]: ${value.reason}');
      });
    }
  });
}
