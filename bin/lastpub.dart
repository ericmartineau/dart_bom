import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';
import 'package:path/path.dart' as path;
import 'package:dart_bom/print_my_version.dart';

Future main(List<String> arguments) {
  final ArgParser argParser = ArgParser();

  argParser.addOption("source",
      abbr: "s",
      help: 'The path to a pubspec file',
      defaultsTo: './pubspec.yaml');
  argParser.addFlag(
    "help",
    abbr: "h",
    help: 'Shows help info',
  );
  var args = argParser.parse(arguments);

  if (args['help'] == true) {
    print(argParser.usage);
    exit(1);
  }

  if (args['source'] == null) {
    print('You must provide a source file');
    exit(1);
  }

  var targetPubspec = resolvePubspec(args.get('source'));
  if (!targetPubspec.existsSync()) {
    print('The source file ${targetPubspec.absolute.path} does not exist');
    exit(1);
  }
  var options = DartVersionOptions(source: targetPubspec.absolute.path);
  return getLastPublishedVersion(options).then(print);
}
