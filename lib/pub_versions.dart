import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
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
  if (!options.isPackageName) {
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
  } else {
    return await getPublishedVersionsForPackage(
      options.source,
      publishedTo: pubUrl,
    );
  }
}

Future<List<DartPackageInfo>> getPackages(String query) async {
  final responses = await Future.wait([1, 2].map((page) => http.get(Uri.parse(
      'https://pub.dev/packages?page=$page&q=${Uri.encodeComponent(query)}'))));
  return responses.expand((e) {
    var found = Document.html(e.body);
    final packages = found.getElementsByClassName('packages-item');

    String? getText(Element source, String className) {
      final found = source.getElementsByClassName(className);
      if (found.isNotEmpty) {
        return found.first.text;
      } else {
        return null;
      }
    }

    return packages.map((e) {
      String? author;
      String? recentVersion;

      e.getElementsByClassName('packages-metadata').forEach((element) {
        var link = element.getElementsByTagName('a').forEach((a) {
          var href = a.attributes['href'];
          if (href != null) {
            if (href.startsWith('/packages')) {
              /// This is the version number
              try {
                recentVersion = Version.parse(a.text).toString();
              } catch (e) {}
            } else if (href.startsWith('/publishers')) {
              author = a.text;
            }
          }
        });
      });

      return DartPackageInfo(
        name: getText(e, 'packages-title'),
        description: getText(e, 'packages-description'),
        author: author,
        recentVersion: recentVersion,
        likes: int.tryParse(getText(e, 'packages-score-value-number') ?? '0'),
        platforms: [],
      );
    }).where((element) =>
        element.name != null &&
        element.name!.toLowerCase().contains(query.toLowerCase()));
  }).toList();
}

String? sanitizeJson(String? string) {
  if (string == null) return null;
  // Invalid string: control characters from U+0000 through U+001F must be escaped at line 2, column 1

  return string.replaceAll(RegExp(r'\n\t\r'), ' ');
}

Future<List<String>> fetchPackageList() async {
  final responses = await http
      .get(Uri.parse('https://pub.dev/api/package-name-completion-data'));
  final json = jsonDecode(responses.body);
  return (json['packages'] as List).cast<String>();
}

class DartPackageInfo {
  final String? name;
  final String? description;
  final String? author;
  final int? likes;
  final List<String>? platforms;
  final String? recentVersion;

  DartPackageInfo({
    this.name,
    this.description,
    this.author,
    this.likes,
    this.recentVersion,
    this.platforms = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': this.name,
      if (description != null) 'description': this.description,
      if (author != null) 'author': this.author,
      if (recentVersion != null) 'recentVersion': this.recentVersion,
      'likes': this.likes,
    }.map((key, value) =>
        MapEntry(key, value is String ? sanitizeJson(value) : value));
  }
}
