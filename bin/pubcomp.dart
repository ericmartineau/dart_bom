import 'dart:convert';

import 'package:dart_bom/commands/autocomplete.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/pub_versions.dart';

Future main(List<String> arguments) async {
  var cmd = AutocompleteCommand(name: 'pubcomp')
    ..argParser.addFlag('extended', abbr: 'e')
    ..argParser.addVerboseFlag();
  await cmd.bootstrap(arguments);
}
