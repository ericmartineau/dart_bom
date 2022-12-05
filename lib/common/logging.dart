import 'package:ansi_styles/ansi_styles.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import 'utils.dart';

final commandColor = AnsiStyles.yellow;
final commandLabelColor = AnsiStyles.yellowBright;
final successMessageColor = AnsiStyles.green;
final successLableColor = AnsiStyles.greenBright;
final warningMessageColor = AnsiStyles.yellow;
final warningLabelColor = AnsiStyles.yellowBright;
final errorMessageColor = AnsiStyles.red;
final errorLabelColor = AnsiStyles.redBright;
final hintMessageColor = AnsiStyles.gray;
final hintLabelColor = AnsiStyles.gray;
final dryRunWarningMessageColor = AnsiStyles.magenta;
final dryRunWarningLabelColor = AnsiStyles.magentaBright;

final commandStyle = AnsiStyles.bold;
final successStyle = AnsiStyles.bold;
final labelStyle = AnsiStyles.bold;

final successLabel = successLableColor(labelStyle('SUCCESS'));
final warningLabel = warningLabelColor(labelStyle('WARNING'));
final errorLabel = errorLabelColor(labelStyle('ERROR'));
final failedLabel = errorLabelColor(labelStyle('FAILED'));
final hintLabel = hintLabelColor(labelStyle('HINT'));
final runningLabel = commandLabelColor(labelStyle('RUNNING'));
final checkLabel = AnsiStyles.greenBright('✓');

final targetStyle = AnsiStyles.cyan.bold;
final packagePathStyle = AnsiStyles.blue;
final packageNameStyle = AnsiStyles.bold;
final errorPackageNameStyle = AnsiStyles.yellow.bold;

abstract class CliLogger implements Logger {
  factory CliLogger(
      {Logger? logger,
      String indentation = '',
      String childIndentation = '  '}) {
    return _CliLogger(
      logger ?? Logger.standard(),
      indentation,
      childIndentation,
    );
  }

  factory CliLogger.of(
      {required bool verbose,
      String indentation = '',
      String childIndentation = '  '}) {
    return _CliLogger(
      verbose ? Logger.verbose() : Logger.standard(),
      indentation,
      childIndentation,
    );
  }

  CliLogger child(
    String message, {
    String prefix = '└> ',
    bool stderr = false,
  });

  CliLogger childWithoutMessage({String childIndentation = '  '});

  void log(String message);

  void command(String command, {bool withDollarSign = false});

  void success(String message, {bool dryRun = false});

  void warning(String message, {bool label = true, bool dryRun = false});

  void error(String message, {bool label = true});

  void hint(String message, {bool label = true});

  void newLine();

  void horizontalLine();
}

/// CLI logger that encapsulates Melos log formatting conventions.
class _CliLogger with _DelegateLogger implements CliLogger {
  const _CliLogger(
    Logger logger,
    String indentation,
    String childIndentation,
  )   : _logger = logger,
        _indentation = indentation,
        _childIndentation = childIndentation;

  @override
  final Logger _logger;
  final String _indentation;
  final String _childIndentation;

  void log(String message) => stdout(message);

  @protected
  Logger get internal {
    return _logger;
  }

  void command(String command, {bool withDollarSign = false}) {
    if (withDollarSign) {
      stdout('${commandColor(r'$')} ${commandStyle(command)}');
    } else {
      stdout(commandColor(commandStyle(command)));
    }
  }

  void success(String message, {bool dryRun = false}) {
    if (dryRun) {
      stdout(successMessageColor(message));
    } else {
      stdout(successMessageColor(successStyle(message)));
    }
  }

  void warning(String message, {bool label = true, bool dryRun = false}) {
    final labelColor =
        dryRun ? dryRunWarningLabelColor : dryRunWarningMessageColor;
    final messageColor =
        dryRun ? dryRunWarningMessageColor : warningMessageColor;
    if (label) {
      stdout('$warningLabel${labelColor(':')} $message');
    } else {
      stdout(messageColor(message));
    }
  }

  void error(String message, {bool label = true}) {
    if (label) {
      stderr('$errorLabel${errorLabelColor(':')} $message');
    } else {
      stderr(errorMessageColor(message));
    }
  }

  void hint(String message, {bool label = true}) {
    if (label) {
      stdout(hintMessageColor('$hintLabel: $message'));
    } else {
      stdout(hintMessageColor(message));
    }
  }

  void newLine() => _logger.write('\n');

  void horizontalLine() => _logger.stdout('-' * terminalWidth);

  @override
  CliLogger child(
    String message, {
    String prefix = '└> ',
    bool stderr = false,
  }) {
    final childIndentation = ' ' * AnsiStyles.strip(prefix).length;
    final logger = CliLogger(
      logger: _logger,
      indentation: '$_indentation$_childIndentation',
      childIndentation: childIndentation,
    );

    final prefixedMessage = '$prefix$message';
    if (stderr) {
      logger.stderr(prefixedMessage);
    } else {
      logger.stdout(prefixedMessage);
    }

    return logger;
  }

  @override
  CliLogger childWithoutMessage({String childIndentation = '  '}) => CliLogger(
        logger: _logger,
        indentation: '$_indentation$_childIndentation',
        childIndentation: childIndentation,
      );

  @override
  void stdout(String message) => _logger.stdout('$_indentation$message');

  @override
  void stderr(String message) => _logger.stderr('$_indentation$message');

  @override
  void trace(String message) => _logger.trace('$_indentation$message');
}

mixin _DelegateLogger implements Logger {
  Logger get _logger;

  @override
  Ansi get ansi => _logger.ansi;

  @override
  bool get isVerbose => _logger.isVerbose;

  @override
  void stdout(String message) => _logger.stdout(message);

  @override
  void stderr(String message) => _logger.stderr(message);

  @override
  void trace(String message) => _logger.trace(message);

  @override
  Progress progress(String message) => _logger.progress(message);

  @override
  void write(String message) => _logger.write(message);

  @override
  void writeCharCode(int charCode) => _logger.writeCharCode(charCode);

  @override
  // ignore: deprecated_member_use
  void flush() => _logger.flush();
}
