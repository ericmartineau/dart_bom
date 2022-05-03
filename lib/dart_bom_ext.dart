import 'dart:io';

import 'package:args/args.dart';
import 'package:pubspec/pubspec.dart';

import 'dart_bom_result.dart';

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
