import 'dart:io';

import 'package:path/path.dart';

extension DirectoryChildren on Directory {
  Directory subdir(String name) {
    return Directory(join(path, name));
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
