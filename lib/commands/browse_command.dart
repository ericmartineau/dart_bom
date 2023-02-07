import 'dart:async';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/pub_versions.dart';

class PackageSearchCommand extends CliCommand<dynamic> {
  PackageSearchCommand({super.name = 'browse'})
      : super(
          description: 'Open a package on pub.dev',
          configureArg: (arg) {},
        );

  @override
  FutureOr<List<PackageInfo>> execute(
      CliLogger logger, ArgResults? argResults) {
    if (argResults?.arguments.isNotEmpty != true) {
      throw ArgParserException('You must provide a querystring argument');
    }
    return getPackages(argResults!.arguments.join(' '));
  }

  String? formatResult(dynamic result) {
    if (result == null) return null;
    if (result is Iterable<PackageInfo>) {
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
