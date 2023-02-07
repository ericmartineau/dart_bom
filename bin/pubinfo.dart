import 'package:args/command_runner.dart';
import 'package:completion/completion.dart' as completion;
import 'package:completion/src/get_args_completions.dart';
import 'package:dart_bom/commands/autocomplete.dart';
import 'package:dart_bom/commands/get_completions_cache.dart';
import 'package:dart_bom/commands/lastpub.dart';
import 'package:dart_bom/commands/list_pub_versions.dart';
import 'package:dart_bom/commands/package_search_command.dart';
import 'package:dart_bom/common/cli_command.dart';

Future main(List<String> arguments) {
  var runner = CommandRunner('pubinfo', 'A collection of utilities around pubs')
    ..argParser.addVerboseFlag()
    ..addCommand(ListPubVersions(name: 'versions', defaultToDir: false))
    ..addCommand(LastVersionCommand())
    ..addCommand(PackageSearchCommand())
    ..addCommand(AutocompleteCommand())
    ..addCommand(GetCompletionsCacheCommand());

  try {
    completion.tryCompletion(
      arguments,
      (List<String> args, String compLine, int compPoint) =>
          getArgsCompletions(runner.argParser, args, compLine, compPoint),
      // ignore: deprecated_member_use_from_same_package,deprecated_member_use
    );
  } catch (e) {
    print(e);
  }
  return runner.run(arguments);
}
