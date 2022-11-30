import 'dart:io';

import 'package:dart_bom/common/platform.dart';
import 'package:path/path.dart';

const envKeyMelosTerminalWidth = 'CLI_TERMINAL_WIDTH';

extension Indent on String {
  String indent(String indent) {
    final split = this.split('\n');

    final buffer = StringBuffer();

    buffer.writeln(split.first);

    for (var i = 1; i < split.length; i++) {
      buffer.write(indent);
      if (i + 1 == split.length) {
        // last line
        buffer.write(split[i]);
      } else {
        buffer.writeln(split[i]);
      }
    }

    return buffer.toString();
  }
}

int get terminalWidth {
  if (currentPlatform.environment.containsKey(envKeyMelosTerminalWidth)) {
    return int.tryParse(
          currentPlatform.environment[envKeyMelosTerminalWidth]!,
          radix: 10,
        ) ??
        80;
  }

  if (stdout.hasTerminal) {
    return stdout.terminalColumns;
  }

  return 80;
}

Iterable<String> gitUrlToFolderPath(String url) {
  if (url.startsWith('git@')) {
    return url.split(':')[1].split('/').map(withoutExtension);
  } else {
    final uri = Uri.parse(url);
    return uri.pathSegments.map(withoutExtension);
  }
}
