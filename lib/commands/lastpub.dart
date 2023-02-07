import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';

class LastVersionCommand extends CliCommand<dynamic> {
  @override
  FutureOr<dynamic?> execute(CliLogger logger, ArgResults? argResults) {
    var options = DartVersionOptions.resolve(argResults?.get('source'));
    return getLastPublishedVersion(options);
  }

  LastVersionCommand({super.name = 'lastpub'})
      : super(
          description: 'Shows the most recently published version to pub.dev',
          configureArg: (arg) => arg
            ..addOption("source",
                abbr: "s",
                help: 'Package name or path to a pubspec file',
                defaultsTo: './pubspec.yaml'),
        );
}
