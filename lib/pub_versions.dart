import 'dart:convert';
import 'dart:io';

import 'package:pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:http/http.dart' as http;

import 'dart_bom.dart';

Uri get pubUrl => Uri.parse('https://pub.dev');
Uri get noneUrl => Uri.parse('none');

Future<Version?> getLastPublishedVersion(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  var all = await getPublishedVersions(options);
  return all.isEmpty ? null : all.first;
}

Future<Version?> getLastVersionsForPackage(String packageName,
    {Uri? publishedTo}) async {
  var list = await getPublishedVersionsForPackage(packageName,
      publishedTo: publishedTo);
  return list.isEmpty ? null : list.first;
}

Future<List<Version>> getPublishedVersionsForPackage(String packageName,
    {Uri? publishedTo}) async {
  if (publishedTo == null || publishedTo == noneUrl) {
    publishedTo = pubUrl;
  }
  if (!publishedTo.path.endsWith('/')) {
    publishedTo = Uri.parse('$publishedTo/');
  }
  final url = publishedTo.resolve('api/packages/$packageName');
  final response = await http.get(url);

  if (response.statusCode == 404) {
    // The package was never published
    return const [];
  } else if (response.statusCode != 200) {
    throw DartBomException(
        'Error reading pub.dev registry for package "$packageName" '
        '(HTTP Status ${response.statusCode}), response: ${response.body}',
        3);
  }
  final versions = <Version>[];
  var jsonBody = json.decode(response.body);
  final versionsRaw = (jsonBody['versions'] as List);
  for (final versionElement in versionsRaw) {
    versions.add(Version.parse(versionElement['version'] as String));
  }
  versions.sort((Version a, Version b) {
    return Version.prioritize(a, b);
  });

  return versions.reversed.toList();
}

Future<List<Version>> getPublishedVersions(
    [DartVersionOptions options = const DartVersionOptions()]) async {
  if (!File(options.source).existsSync()) {
    throw DartBomException('File ${options.source} does not exist', 2);
  }
  var pubspec = await PubSpec.loadFile(options.source);
  var name = pubspec.name!;
  Uri? pubHosted = pubspec.publishTo;
  if (pubHosted?.hasScheme != true) {
    pubHosted = pubUrl;
  }

  return await getPublishedVersionsForPackage(name, publishedTo: pubHosted);
}
