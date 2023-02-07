import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:args/args.dart';
import 'package:dart_bom/common/cli_command.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/pub_versions.dart';

class GetCompletionsCacheCommand extends CliCommand<dynamic> {
  GetCompletionsCacheCommand({super.name = 'getcompletions'})
      : super(
          description: 'Fetches all package names for autocompletion',
          configureArg: (arg) {
            arg
              ..addOption('output',
                  abbr: 'o',
                  help: 'Output folder to write cache files',
                  mandatory: true);
          },
        );

  @override
  Future execute(CliLogger logger, ArgResults? argResults) async {
    var output = argResults!['output'] as String;

    var resolvedPath = resolvePath(output);
    if (!Directory(resolvedPath).existsSync()) {
      throw ArgParserException('Output directory $resolvedPath does not exist');
    }

    final buckets = <String, List<String>>{};
    final packageList = await fetchPackageList();
    logger.write('Fetched ${packageList.length} package names');
    for (var item in packageList) {
      buckets.putIfAbsent(item[0], () => []).add(item);
    }
    var dir = Directory(path.join(resolvedPath, '.dart-pub-indexes'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    buckets.forEach((key, value) {
      logger.success('Output letter: ${key}: ${value.length} items');
      File(path.join(dir.absolute.path, key)).writeAsStringSync(
        value.join('\n'),
      );
    });
    File(path.join(dir.absolute.path, '_all'))
        .writeAsStringSync(packageList.join(' '));
  }
}
