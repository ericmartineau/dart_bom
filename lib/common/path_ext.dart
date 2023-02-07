import 'dart:io';

import 'package:path/path.dart';

extension FileChildren on File {
  File sibling(String name) {
    return parent.child(name);
  }
}

extension DirectoryChildren on Directory {
  Directory subdir(String name) {
    return Directory(join(path, name));
  }

  String resolvePath(String path) {
    if (path.contains('~')) {
      path = path.replaceAll('~', userHomePath!);
    }
    return path;
  }

  File child(String name) {
    return File(join(path, name));
  }

  Directory subdirs(Iterable<String> name) {
    return Directory(joinAll([path, ...name]));
  }

  bool contains(String path) {
    return subdir(path).existsSync();
  }

  ParentFilter findParent(bool predicate(Directory directory)) {
    final parents = <String>[];
    var d = this;
    while (d.parent.existsSync() && !predicate(d)) {
      parents.add(d.name);
      d = d.parent;
    }

    return ParentFilter(!predicate(d) ? null : d, parents);
  }

  String get name {
    return split(this.absolute.path).where((e) => e != '.' && e != '..').last;
  }
}

class ParentFilter {
  final Directory? found;
  final List<String> path;

  ParentFilter(this.found, this.path);
}

String? get userHomePath {
  var envVars = Platform.environment;
  if (Platform.isMacOS) {
    return envVars['HOME'];
  } else if (Platform.isLinux) {
    return envVars['HOME'];
  } else if (Platform.isWindows) {
    return envVars['UserProfile'];
  }
  return null;
}
