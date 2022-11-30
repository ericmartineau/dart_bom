import 'dart:io';

import 'package:dart_bom/common/utils.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/git/git.dart';
import 'package:dart_bom/repos_config.dart';
import 'package:path/path.dart';
import 'package:pubspec/pubspec.dart';

import 'checkout_local.dart';

/// Creates a pubspec override in this project
Future<PubSpec> createPubspecOverrides(
    DartReposOptions options, LogFn logger) async {
  var workingDir = Directory(options.workingDirectory);

  final dependencies = <String, DependencyReference>{};
  for (var entry in options.repos.sources.entries) {
    final gitValue = entry.value.git;
    String? localExpectedPath() {
      if (gitValue == null) return null;
      final baseCheckoutPath = options.repos.checkoutRoot?.split("/") ?? [];
      final baseFolderPath = gitUrlToFolderPath(gitValue.url);
      return '/${joinAll([
            ...baseCheckoutPath,
            ...baseFolderPath,
            if (gitValue.path != null) gitValue.path!,
          ])}';
    }

    var checkoutMode = entry.value.mode ?? options.repos.defaultMode;
    if (entry.value.git == null) {
      checkoutMode = CheckoutMode.published;
    }

    var projectName = entry.key;
    switch (checkoutMode) {
      case CheckoutMode.local:
        var localPath = localExpectedPath();
        if (options.checkout && !Directory(localPath!).existsSync()) {
          logger('Checking out $projectName');
          final res = await checkoutProject(
            projectName,
            gitValue!,
            Directory(options.repos.checkoutRoot!),
          );
          if (!res.success) {
            logger("Failed to checkout $localPath");
            for (var message in res.messages) {
              logger('   $message');
            }
          }
        }
        dependencies[projectName] = PathReference(localPath);
        break;
      case CheckoutMode.git:
        dependencies[projectName] = entry.value.git!;
        break;
      case CheckoutMode.published:
      case CheckoutMode.unpublished:
        var result = await getMyVersionConstraint(
          published: entry.value.mode != CheckoutMode.unpublished,
          name: projectName,
          localPubspecFile: localExpectedPath(),
        );
        dependencies[projectName] = result.dependency;
        break;
    }
  }

  final spec = PubSpec(
      name:
          'repospec_${split(workingDir.absolute.path).where((e) => e != '.' && e != '..').last}',
      dependencies: dependencies);

  return spec;
}
