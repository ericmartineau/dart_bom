import 'dart:io';

import 'package:pubspec/pubspec.dart';

import 'dart_bom.dart';

Future<String> getMyVersion(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  late PubSpec sourcePubspec;

  try {
    var loadFile = PubSpec.loadFile(options.source);
    sourcePubspec = await loadFile;
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse ${options.source} as a pubspec.yaml: $e', 2);
  }

  var myVersion = '';
  if (sourcePubspec.publishTo != null) {
    myVersion += ("  ${sourcePubspec.name}:\n");
    myVersion += ("    hosted: ${sourcePubspec.publishTo}\n");
    myVersion += ("    version: ^${sourcePubspec.version}\n");
  } else {
    myVersion += ("  ${sourcePubspec.name}: ^${sourcePubspec.version}\n");
  }
  return myVersion;
}
