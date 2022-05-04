import 'package:pubspec/pubspec.dart';

enum DependencyLocation { dependencies, devDependencies, dependencyOverrides }

class DartBomException implements Exception {
  final int exitCode;
  final String message;

  const DartBomException(this.message, this.exitCode);

  @override
  String toString() {
    return "(${exitCode}) $message";
  }
}

class DependencyMismatch {
  final DependencyLocation location;
  final DependencyReference original;
  final DependencyReference fromBom;
  final String package;
  String? reason;

  DependencyMismatch(
    this.location,
    this.original,
    this.fromBom,
    this.package, [
    this.reason,
  ]);
}

class DartBomResult {
  final List<DependencyMismatch> mismatches;
  final List<DependencyMismatch> matches;
  final List<DependencyMismatch> skipped;

  final PubSpec sourcePubspec;
  final PubSpec targetPubspec;

  final String sourceFile;
  final String targetFile;

  const DartBomResult({
    required this.mismatches,
    required this.matches,
    required this.skipped,
    required this.sourcePubspec,
    required this.targetPubspec,
    required this.sourceFile,
    required this.targetFile,
  });
}
