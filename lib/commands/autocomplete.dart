import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';

class AutocompleteCommand extends CliCommand<dynamic> {
  AutocompleteCommand({super.name = 'autocomplete'})
      : super(
          description: 'Fetches all package names for autocompletion',
          configureArg: (arg) {
            arg
              ..addFlag('local', abbr: 'l')
              ..addFlag('json', abbr: 'j')
              ..addOption('cache', abbr: 'c', help: 'Cache base dir');
          },
        );

  @override
  String? formatResult(CommandResult result) {
    final packages = result.get<List<DartPackageInfo>>();

    if (result.args?['json'] == true) {
      return jsonEncode(packages.map((e) => e.toMap()).toList());
    } else {
      return packages.map((e) => e.name).join(' ');
    }
  }

  @override
  Future<List<DartPackageInfo>> execute(
      CliLogger logger, ArgResults? argResults) async {
    if (argResults!['local'] == true) {
      var cacheDir = argResults.get<String>('cache', '~/.zsh');
      var resolvedPath = resolvePath(cacheDir);
      if (argResults.arguments.isEmpty) {
        return const [];
      }
      final query = argResults.arguments.first;
      var rootDir = Directory(resolvedPath);
      var indexDir = rootDir.subdir('.dart-pub-indexes');
      if (!rootDir.existsSync()) {
        throw ArgParserException(
            'Cache directory $resolvedPath does not exist');
      } else if (!indexDir.existsSync()) {
        throw ArgParserException(
            'No caches downloaded.  Run getcompletions first');
      } else {
        final firstLetter = query[0].toLowerCase();
        final lines = indexDir.child(firstLetter).readAsLinesSync();
        int found = 0;
        var results = <DartPackageInfo>[];
        for (var line in lines) {
          if (found >= 10) {
            break;
          }
          if (line.startsWith(query) && found++ < 10) {
            results.add(DartPackageInfo(name: line));
          }
        }
        return results;
      }
    } else {
      final query = argResults.arguments.firstWhere(
        (element) => true,
        orElse: () => 'a',
      );
      final packages = await getPackages(query);
      return packages;
    }
  }
}
