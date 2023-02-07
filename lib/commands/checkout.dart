import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dart_bom/checkout_local.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/repos_config.dart';

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
  final logger = CliLogger(logger: Logger.standard());

  await checkoutLocal(options, logger);
}
