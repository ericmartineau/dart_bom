import 'dart:convert';
import 'dart:io';

import 'package:dart_bom/common/utils.dart';
import 'package:dart_bom/pub_versions.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

import 'dart_bom.dart';

Future<String> getMyVersion(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  final result = await getMyVersionConstraint(
    localPubspecFile: options.source,
    published: options.published,
  );

  var myVersion = '';
  myVersion += ("  ${result.name}:\n");
  myVersion += json.encode(result.dependency.toJson()).indent('    ');
  return myVersion;
}

Future<PubDependencyReference> getMyVersionConstraint({
  String? name,
  String? localPubspecFile,
  bool published = true,
}) async {
  PubSpec? sourcePubspec;

  try {
    if (localPubspecFile != null) {
      var loadFile = PubSpec.loadFile(localPubspecFile);
      sourcePubspec = await loadFile;
      name ??= sourcePubspec.name;
      assert(name == sourcePubspec.name, "Name and pubspec should match");
    }
  } catch (e) {
    throw DartBomException(
        'ERROR: Unable to parse ${localPubspecFile} as a pubspec.yaml: $e', 2);
  }

  String _name() =>
      _expect<String>(name, 'No pubspec name could be determined!');

  Version? versionToUse = published
      ? (await getLastVersionsForPackage(_name(),
          publishedTo: sourcePubspec?.publishTo))
      : _expect(sourcePubspec,
              'To use non-published version, you must have a locally checked out copy')
          .version;

  if (sourcePubspec?.publishTo == noneUrl || versionToUse == null) {
    return PubDependencyReference(
      _name(),
      PathReference(
        File(_expect(localPubspecFile,
                'Expected a local checked out copy for publish_to: none project'))
            .parent
            .absolute
            .path,
      ),
    );
  } else if (sourcePubspec?.publishTo != null) {
    return PubDependencyReference(
        _name(),
        ExternalHostedReference(_name(), sourcePubspec!.publishTo?.toString(),
            VersionConstraint.compatibleWith(versionToUse), true));
  } else {
    return PubDependencyReference(_name(),
        HostedReference(VersionConstraint.compatibleWith(versionToUse)));
  }
}

T _expect<T>(T? source, [String? message]) {
  if (source is! T) {
    throw StateError(message ?? 'Expected a non-null value of ${T}');
  }
  return source;
}

class PubDependencyReference {
  final String name;
  final DependencyReference dependency;

  const PubDependencyReference(this.name, this.dependency);
}
