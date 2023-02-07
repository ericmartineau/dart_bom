import 'package:args/command_runner.dart';
import 'package:dart_bom/commands/lastpub.dart';
import 'package:dart_bom/commands/list_pub_versions.dart';
import 'package:dart_bom/commands/package_search_command.dart';
import 'package:dart_bom/common/cli_command.dart';

Future main(List<String> arguments) {
  var runner = CommandRunner('pubinfo', 'A collection of utilities around pubs')
    ..argParser.addVerboseFlag()
    ..addCommand(ListPubVersions(name: 'versions', defaultToDir: false))
    ..addCommand(LastVersionCommand())
    ..addCommand(PackageSearchCommand());
  return runner.run(arguments);
}
