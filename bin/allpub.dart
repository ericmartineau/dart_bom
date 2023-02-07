import 'package:dart_bom/commands/list_pub_versions.dart';
import 'package:dart_bom/common/cli_command.dart';

// ALl

Future main(List<String> arguments) {
  var cmd = ListPubVersions(name: 'allpub', defaultToDir: false)
    ..argParser.addVerboseFlag();
  return cmd.bootstrap(arguments);
}
