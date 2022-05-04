import 'dart:io';

import 'package:dart_bom/pub_versions.dart';
import 'package:pub_semver/pub_semver.dart';
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

  var sourceFile = File(options.source);
  Version? versionToUse = options.published
      ? (await getLastVersionsForPackage(sourcePubspec.name!,
          publishedTo: sourcePubspec.publishTo))
      : sourcePubspec.version;

  if (sourcePubspec.publishTo == noneUrl || versionToUse == null) {
    var myVersion = '';
    myVersion += ("  ${sourcePubspec.name}:\n");
    myVersion += ("    path: ${sourceFile.parent.absolute.path}\n");
    return myVersion;
  } else if (sourcePubspec.publishTo != null) {
    var myVersion = '';
    myVersion += ("  ${sourcePubspec.name}:\n");
    myVersion += ("    hosted: ${sourcePubspec.publishTo}\n");
    myVersion += ("    version: ^${versionToUse}\n");
    return myVersion;
  } else {
    return "  ${sourcePubspec.name}: ^${versionToUse}\n";
  }
}
