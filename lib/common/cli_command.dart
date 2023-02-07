import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dart_bom/common/logging.dart';

typedef CliCommandExec<R> = FutureOr<R> Function(
    CliLogger logger, ArgResults args);

abstract class CliCommand<R> extends Command<R> {
  CliCommand({
    required this.name,
    required this.description,
    required this.configureArg,
    List<CliCommand> commands = const [],
  })  : commands = {},
        super() {
    configureArg(argParser);
    for (var value in commands) {
      addCliCommand(value);
    }
  }

  final void Function(ArgParser parser) configureArg;
  final String name;
  final String description;

  final Map<String, CliCommand> commands;

  void addCliCommand(CliCommand subCommand) {
    addSubcommand(subCommand as Command<R>);
    commands[subCommand.name] = subCommand;
  }

  String? formatResult(R? result) {
    if (result == null) return null;
    if (result is Iterable) {
      return result.map((e) => e.toString()).join('\n');
    } else {
      return result.toString();
    }
  }

  FutureOr<R> internalRun(
      CliLogger log, bool isVerbose, ArgResults? argResults) async {
    try {
      final res = await this.execute(log, argResults);
      final logged = formatResult(res);
      if (logged != null) {
        log.log(logged);
      }
      return res!;
    } on ArgumentError catch (e) {
      log.error('Unexpected error: ${e}');
      log.error(argParser.usage, label: false);
      return null as R;
    } catch (e, stack) {
      log.error('Unexpected error: ${e}');
      if (isVerbose) {
        print(stack);
      }
      rethrow;
    }
  }

  FutureOr<R> run() async {
    final isVerbose = globalResults?['verbose'] == true;
    final log = CliLogger(
      logger: isVerbose ? Logger.verbose() : Logger.standard(),
    );

    return internalRun(log, isVerbose, argResults);
  }

  FutureOr<R?> execute(CliLogger logger, ArgResults? argResult);

  Future<void> bootstrap(List<String> args) async {
    ArgResults? argResults;
    try {
      argResults = argParser.parse(args);
    } catch (e) {
      final log = CliLogger(logger: Logger.standard());

      if (e is ArgParserException) {
        log.error('${e.message}', label: false);
        log.error('', label: false);
        log.flush();
      } else {
        log.error('Error parsing args: $e', label: false);
      }
      log.error(argParser.usage, label: false);
      return;
    }

    var isVerbose = argResults['verbose'] == true;
    final log = CliLogger(
      logger: isVerbose ? Logger.verbose() : Logger.standard(),
    );
    await internalRun(log, isVerbose, argResults);
  }
}

ArgParser createArgs(void configure(ArgParser parser)?) {
  final args = ArgParser();
  if (configure != null) configure.call(args);
  return args;
}

extension AddCommonArgsExt on ArgParser {
  ArgParser addVerboseFlag() {
    this.addFlag('verbose', abbr: 'v');
    return this;
  }
}

final globalArgs = ArgParser(allowTrailingOptions: true)
  ..addFlag('verbose', abbr: 'v');

ArgResults parseGlobalArgs(List<String> results) {
  return globalArgs.parse(results);
}
