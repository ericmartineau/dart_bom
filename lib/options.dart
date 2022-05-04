class DartVersionOptions {
  final String source;
  final bool published;

  const DartVersionOptions(
      {this.source = './pubspec.yaml', this.published = false});
}

class DartBomOptions {
  final String? _source;
  final String target;
  final bool writeFiles;
  final bool overwritePathDependencies;
  final bool overwriteDependencyOverrides;
  final bool backupFiles;

  const DartBomOptions(
      {String? source,
      this.target = './pubspec.yaml',
      this.writeFiles = false,
      this.backupFiles = true,
      this.overwritePathDependencies = false,
      this.overwriteDependencyOverrides = true})
      : _source = source;

  String get source => _source ?? (throw 'Missing source file');

  @override
  String toString() {
    return [
      if (_source != null) ...['-s', _source!],
      '-t',
      target,
      if (writeFiles) '-w',
      if (overwritePathDependencies) '-p',
      if (overwriteDependencyOverrides) '-o',
      if (!backupFiles) '-b',
    ].join(' ');
  }
}
