import 'dart:convert';
import 'dart:io';

import 'package:pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:http/http.dart' as http;

import 'dart_bom.dart';

Uri get pubUrl => Uri.parse('https://pub.dev');

Future<Version?> getLastPublishedVersion(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  if (!File(options.source).existsSync()) {
    throw DartBomException('File ${options.source} does not exist', 2);
  }
  var pubspec = await PubSpec.loadFile('./pubspec.yaml');
  var name = pubspec.name!;
  var pubHosted = pubspec.publishTo ?? pubUrl;

  final url = pubHosted.replace(path: '/packages/$name.json');
  final response = await http.get(url);

  if (response.statusCode == 404) {
    // The package was never published
    return null;
  } else if (response.statusCode != 200) {
    throw DartBomException(
        'Error reading pub.dev registry for package "$name" '
        '(HTTP Status ${response.statusCode}), response: ${response.body}',
        3);
  }
  final versions = <Version>[];
  final versionsRaw =
      (json.decode(response.body) as Map)['versions'] as List<Object?>;
  for (final versionElement in versionsRaw) {
    versions.add(Version.parse(versionElement as String));
  }
  versions.sort((Version a, Version b) {
    return Version.prioritize(a, b);
  });

  return versions.reversed.toList().first;
}

Future<List<Version>> getPublishedVersions(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  if (!File(options.source).existsSync()) {
    throw DartBomException('File ${options.source} does not exist', 2);
  }
  var pubspec = await PubSpec.loadFile('./pubspec.yaml');
  var name = pubspec.name!;
  var pubHosted = pubspec.publishTo ?? pubUrl;

  final url = pubHosted.replace(path: '/packages/$name.json');
  final response = await http.get(url);

  if (response.statusCode == 404) {
    // The package was never published
    return const [];
  } else if (response.statusCode != 200) {
    throw DartBomException(
        'Error reading pub.dev registry for package "$name" '
        '(HTTP Status ${response.statusCode}), response: ${response.body}',
        3);
  }
  final versions = <Version>[];
  final versionsRaw =
      (json.decode(response.body) as Map)['versions'] as List<Object?>;
  for (final versionElement in versionsRaw) {
    versions.add(Version.parse(versionElement as String));
  }
  versions.sort((Version a, Version b) {
    return Version.prioritize(a, b);
  });

  return versions.reversed.toList();
}