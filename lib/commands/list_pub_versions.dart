import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';
import 'package:pub_semver/pub_semver.dart';

class ListPubVersions extends CliCommand<dynamic> {
  ListPubVersions({super.name = 'allpub', bool defaultToDir = true})
      : super(
            description: 'Lists all pub.dev versions for this package',
            configureArg: (arg) => arg
              ..addOption("source",
                  abbr: "s",
                  help: 'The path to a pubspec file, or a package name',
                  mandatory: false,
                  defaultsTo: defaultToDir ? './pubspec.yaml' : null));

  @override
  FutureOr<List<Version>?> execute(CliLogger logger, ArgResults? argResults) {
    return getPublishedVersions(
      DartVersionOptions.resolve(
        argResults?['source'] ??
            argResults?.arguments.firstWhere(
              (element) => true,
              orElse: () => '',
            ),
      ),
    );
  }

  @override
  String? formatResult(dynamic list) {
    if (list == null)
      return "No results";
    else
      return (list as List).map((e) => e.toString()).join('\n');
  }
}
