import 'package:dart_bom/dart_bom.dart';
import 'package:pubspec/pubspec.dart';

typedef DependencyMap = Map<String, DependencyReference>;

extension PubspecMergeExt on PubSpec {
  DependencyMap getDependencies(DependencyLocation location) {
    switch (location) {
      case DependencyLocation.dependencies:
        return this.dependencies;
      case DependencyLocation.devDependencies:
        return this.devDependencies;
      case DependencyLocation.dependencyOverrides:
        return this.dependencyOverrides;
    }
  }

  PubSpec merge(PubSpec other) {
    return this.copy(
      name: other.name,
      author: other.author,
      description: other.description,
      documentation: other.documentation,
      environment: other.environment,
      homepage: other.homepage,
      publishTo: other.publishTo,
      version: other.version,
      dependencies: {
        ...this.dependencies,
        ...other.dependencies,
      },
      devDependencies: {
        ...this.devDependencies,
        ...other.devDependencies,
      },
      dependencyOverrides: {
        ...this.dependencyOverrides,
        ...other.dependencyOverrides,
      },
      executables: {
        ...this.executables,
        ...other.executables,
      },
      platforms: {
        ...platforms,
        ...other.platforms,
      },
    );
  }
}
