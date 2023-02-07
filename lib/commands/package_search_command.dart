import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';
import 'package:pub_semver/pub_semver.dart';

class PackageSearchCommand extends CliCommand<dynamic> {
  PackageSearchCommand({super.name = 'search', bool defaultToDir = true})
      : super(
          description: 'Searches for packages on pub.dev',
          configureArg: (arg) => arg
            ..addOption("query",
                abbr: "q", help: 'The search term', mandatory: true),
        );

  @override
  FutureOr<List<String>> execute(CliLogger logger, ArgResults? argResults) {
    return getPackages(argResults!.get("query"));
  }
}
