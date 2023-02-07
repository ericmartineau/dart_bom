import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/local_pubspec.dart';
import 'package:dart_bom/repos_config.dart';
import 'package:yaml_writer/yaml_writer.dart';

Future main(List<String> arguments) async {
  final ArgParser argParser = ArgParser();

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

  var targetRepos = resolveRepos();
  if (!targetRepos.existsSync()) {
    print('The source file ${targetRepos.absolute.path} does not exist');
    exit(1);
  }

  final repos = ReposConfig.read(targetRepos.path);
  var options = DartReposOptions(
    repos: repos,
    workingDirectory: targetRepos.parent.path,
  );
  final logger = CliLogger(Logger.standard());

  final pubspec = await createPubspecOverrides(options, logger.log);

  print("# --------------------------------------------------------- ");
  print("# DO NOT EDIT THIS FILE - IT WAS AUTOMATICALLY GENERATED");
  print("#");
  print("# To update this file, run: \$ repospec ");
  print("# --------------------------------------------------------- ");
  print(YAMLWriter().write(pubspec.toJson()));
}
