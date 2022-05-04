import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/print_my_version.dart';

Future main(List<String> arguments) {
  try {
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

    argParser.addFlag(
      "published",
      abbr: "p",
      help: 'Last published',
      defaultsTo: false,
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
    var sourceFile = resolvePubspec(args.get('source'));
    if (!sourceFile.existsSync()) {
      print('The source file ${sourceFile.absolute.path} does not exist');
      exit(1);
    }
    var options = DartVersionOptions(
      source: sourceFile.absolute.path,
      published: args.get('published'),
    );

    return getMyVersion(options).then(print);
  } catch (e, stack) {
    if (e is DartBomException) {
      print(e);
      exit(e.exitCode);
    } else {
      print('Unknown error: $e');
      print(stack);
      exit(127);
    }
  }
}
