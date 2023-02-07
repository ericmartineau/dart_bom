import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';

class PackageSearchCommand extends CliCommand<dynamic> {
  PackageSearchCommand({super.name = 'search', bool defaultToDir = true})
      : super(
          description: 'Searches for packages on pub.dev',
          configureArg: (arg) => arg
            ..addOption("query",
                abbr: "q", help: 'The search term', mandatory: true)
            ..addFlag('only-name', abbr: 'o', help: 'Show only name only'),
        );

  @override
  FutureOr<List<DartPackageInfo>> execute(
      CliLogger logger, ArgResults? argResults) {
    return getPackages(argResults!.get("query"));
  }

  String? formatResult(dynamic result) {
    if (result == null) return null;
    if (result is Iterable<DartPackageInfo>) {
      if (argResults!['only-name'] == true) {
        return result.map((e) => e.name).join('\n');
      } else {
        return result.map((e) {
          return e.toMap().entries.map((entry) {
            var key = entry.key;
            var value = entry.value.toString().trim();
            return '$key: $value';
          }).join('\n');
        }).join('\n-------------\n');
      }
    } else {
      return result.toString();
    }
  }
}
