import 'package:equatable/equatable.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:yaml/yaml.dart';

import 'common/io.dart';

enum CheckoutMode {
  git,
  local,
  published,
  unpublished;

  static CheckoutMode parse(String input) {
    for (final mode in CheckoutMode.values) {
      if (mode.name == input.toLowerCase()) {
        return mode;
      }
    }
    if (input == 'pub') {
      return CheckoutMode.published;
    }
    throw ArgumentError(
      'Invalid argument: $input: '
      'Expected one of ${CheckoutMode.values}',
    );
  }

  static CheckoutMode? tryParse(String? input) {
    if (input == null) return null;
    return parse(input);
  }
}

class PackageCheckoutConfig extends Equatable {
  const PackageCheckoutConfig({
    required this.git,
    this.version,
    this.repo,
    this.mode,
    this.source,
  });

  factory PackageCheckoutConfig.fromJson(
    String key,
    dynamic json,
  ) {
    GitReference? git;
    VersionConstraint? version;
    String? repo;
    CheckoutMode? mode;
    String? source;

    json ??= {};
    if (json is String) {
      version = VersionConstraint.parse(json);
    } else if (json is Map<Object?, Object?>) {
      final gitConfig = json['git'];
      final versionConfig = json['version'];
      final modeConfig = json['mode'];
      if (gitConfig != null) {
        try {
          git = GitReference.fromJson({'git': gitConfig});
        } catch (e) {
          throw StateError(
            'Invalid configuration for package $key: '
            'the git property must match a pubspec git definition',
          );
        }
      } else {
        throw StateError(
          'Invalid configuration for package $key: '
          'the git property is required',
        );
      }

      if (versionConfig is String) {
        try {
          version = VersionConstraint.parse(versionConfig);
        } catch (e) {
          throw StateError(
            'Invalid configuration for package $key: '
            'the version property must match a pubspec version constraint',
          );
        }
      }
      repo = json['repo'] as String?;
      if (modeConfig is String) {
        mode = CheckoutMode.parse(modeConfig);
      }

      if (json['source'] is String) {
        source = json['source'] as String;
      }
    }

    return PackageCheckoutConfig(
      git: git,
      repo: repo,
      version: version,
      mode: mode,
      source: source,
    );
  }

  final GitReference? git;
  final VersionConstraint? version;
  final String? repo;
  final CheckoutMode? mode;
  final String? source;

  Map<String, Object?> toJson() {
    return {
      if (source != null) 'source': source,
      if (git != null) 'git': git!.toJson()['git'],
      if (repo != null) 'repo': repo,
      if (version != null) 'version': version?.toString(),
      if (mode != null) 'mode': mode?.name,
    };
  }

  @override
  List<Object?> get props => [git, repo, version, mode];

  @override
  bool get stringify => true;
}

class ReposConfig extends Equatable {
  const ReposConfig({
    this.checkoutRoot,
    this.defaultMode = CheckoutMode.published,
    this.defaultRef,
    this.defaultBase,
    this.sources = const {},
  });

  factory ReposConfig.fromYaml(Map<Object?, Object?> yaml) {
    final defaultMode = CheckoutMode.tryParse(yaml['defaultMode'] as String?);
    return ReposConfig(
      checkoutRoot: yaml['checkoutRoot'] as String?,
      defaultMode: defaultMode ?? CheckoutMode.published,
      defaultRef: yaml['defaultRef'] as String?,
      defaultBase: yaml['defaultBase'] as String?,
      sources: {
        for (final entry
            in ((yaml['sources'] ?? {}) as Map<Object?, Object?>).entries)
          entry.key.toString(): PackageCheckoutConfig.fromJson(
            entry.key.toString(),
            entry.value,
          ),
      },
    );
  }

  factory ReposConfig.read(String yamlPath) {
    final yamlString = readTextFile(yamlPath);
    final yaml = loadYamlDocument(yamlString, sourceUrl: Uri.parse(yamlPath));
    return ReposConfig.fromYaml(yaml.contents as YamlMap);
  }

  static const empty = ReposConfig();

  final Map<String, PackageCheckoutConfig> sources;
  final String? checkoutRoot;
  final CheckoutMode defaultMode;
  final String? defaultRef;
  final String? defaultBase;

  Map<String, Object?> toJson() {
    return {
      'sources': {for (final en in sources.entries) en.key: en.value.toJson()},
      'checkoutRoot': checkoutRoot,
      'defaultMode': defaultMode.name,
      if (defaultRef != null) 'defaultRef': defaultRef,
      if (defaultBase != null) 'defaultBase': defaultBase,
    };
  }

  @override
  List<Object?> get props => [
        defaultRef,
        sources,
        checkoutRoot,
        defaultMode,
        defaultBase,
      ];

  @override
  bool get stringify => true;

  ReposConfig copyWith({
    Map<String, PackageCheckoutConfig>? sources,
    String? checkoutRoot,
    CheckoutMode? defaultMode,
    String? defaultRef,
    String? defaultBase,
  }) {
    return ReposConfig(
      sources: {
        ...this.sources,
        ...?sources,
      },
      checkoutRoot: checkoutRoot ?? this.checkoutRoot,
      defaultRef: defaultRef ?? this.defaultRef,
      defaultBase: defaultBase ?? this.defaultBase,
      defaultMode: defaultMode ?? this.defaultMode,
    );
  }
}
