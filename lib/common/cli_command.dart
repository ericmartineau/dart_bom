import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:completion/completion.dart';
import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/pub_versions.dart';

typedef CliCommandExec<R> = FutureOr<R> Function(
    CliLogger logger, ArgResults args);

abstract class CliCommand<R> extends Command<CommandResult<R>> {
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
    addSubcommand(subCommand as Command<CommandResult<R>>);
    commands[subCommand.name] = subCommand;
  }

  String? formatResult(CommandResult<R> res) {
    final result = res.result;
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
      final logged = formatResult(CommandResult(res, argResults, log));
      if (logged != null) {
        log.log(logged);
      }
      return res as R;
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

  FutureOr<CommandResult<R>> run() async {
    final isVerbose = globalResults?['verbose'] == true;
    final log = CliLogger(
      logger: isVerbose ? Logger.verbose() : Logger.standard(),
    );

    final result = await internalRun(log, isVerbose, argResults);
    return CommandResult(result, argResults, log);
  }

  FutureOr<R?> execute(CliLogger logger, ArgResults? argResult);

  Future<CommandResult<R>> bootstrap(List<String> args) async {
    ArgResults? argResults;
    try {
      argResults = tryArgsCompletion(args, argParser);
    } catch (e) {
      final log = CliLogger(logger: Logger.standard());

      if (e is ArgParserException) {
        log.error('${e.message}', label: false);
        log.error('', label: false);
      } else {
        log.error('Error parsing args: $e', label: false);
      }
      log.error(argParser.usage, label: false);
      return CommandResult(null, argResults, log);
    }

    var isVerbose = argResults['verbose'] == true;
    final log = CliLogger(
      logger: isVerbose ? Logger.verbose() : Logger.standard(),
    );
    final res = await internalRun(log, isVerbose, argResults);
    return CommandResult(res, argResults, log);
  }
}

class CommandResult<T> {
  final T? result;
  final ArgResults? args;
  final CliLogger log;
  CommandResult(this.result, this.args, this.log);

  CommandResult<TT> cast<TT>() {
    return CommandResult(result as TT, args, log);
  }

  TT get<TT>() {
    return result as TT;
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
