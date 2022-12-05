import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/sync_pubspec_shared.dart';
import 'package:pubspec/pubspec.dart';

import 'dart_bom.dart';

Future<DartBomResult> syncPubspecFiles(CliLogger logger,
    [DartBomOptions options = const DartBomOptions()]) async {
  late PubSpec sourcePubspec;
  late PubSpec targetPubspec;

  try {
    var loadFile = PubSpec.loadFile(options.source);
    sourcePubspec = await loadFile;
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse ${options.source} as a pubspec.yaml: $e', 2);
  }
  try {
    targetPubspec = await PubSpec.loadFile(options.target);
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse target ${options.target} as a pubspec.yaml: $e',
        2);
  }

  final bomResult = syncPubspecData(
    sourcePubspec,
    targetPubspec,
    logger: logger,
    options: options,
  );

  return bomResult;
}
