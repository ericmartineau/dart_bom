import 'dart:io';

import 'package:args/args.dart';
import 'package:pubspec/pubspec.dart';

import 'dart_bom_result.dart';
import 'package:path/path.dart' as path;

extension DependencyLocationExt on DependencyLocation {
  String get value {
    return "$this".replaceAll('DependencyLocation.', '');
  }
}

extension ArgResultsCastingGetterExt on ArgResults {
  T get<T>(String key, [T? defaultValue]) {
    return (this[key] as T? ?? defaultValue!);
  }
}

extension PubSpecWriteAnywhereExt on PubSpec {
  Future writeToFile(File targetFile) {
    final ioSink = targetFile.openWrite();
    try {
      YamlToString().writeYamlString(this.toJson(), ioSink);
    } catch (e) {
      throw DartBomException('$e', 5);
    } finally {
      return ioSink.close();
    }
  }

  Future writeTo(String targetFileName) {
    return writeToFile(File(targetFileName));
  }
}

String resolvePath(String pathName) {
  if (pathName.startsWith('~/')) {
    var homeDir = userHomeDir;
    if (homeDir != null) {
      pathName = path.join(homeDir, pathName.substring(2));
    }
  }
  return pathName;
}

File resolvePubspec([String? providedPath]) {
  var pathName = providedPath ?? './pubspec.yaml';
  pathName = resolvePath(pathName);
  if (!pathName.endsWith('pubspec.yaml')) {
    pathName = path.join(pathName, 'pubspec.yaml');
  }
  var directFile = File(pathName);
  return directFile;
}

// Get the home directory or null if unknown.
String? get userHomeDir {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Platform.environment['HOME'];
    case 'windows':
      return Platform.environment['USERPROFILE'];
    case 'android':
      // Probably want internal storage.
      return '/storage/sdcard0';
    case 'ios':
      // iOS doesn't really have a home directory.
      return null;
    case 'fuchsia':
      // I have no idea.
      return null;
    default:
      return null;
  }
}
