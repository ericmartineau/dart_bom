import 'package:dart_bom/commands/autocomplete.dart';
import 'package:dart_bom/common/cli_command.dart';

// ALl

Future main(List<String> arguments) {
  var cmd = AutocompleteCommand(name: 'pubcomp')..argParser.addVerboseFlag();
  return cmd.bootstrap(arguments);
}
