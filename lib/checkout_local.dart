import 'dart:io';

import 'package:dart_bom/common/logging.dart';
import 'package:dart_bom/dart_bom.dart';
import 'package:dart_bom/git/git.dart';
import 'package:dart_bom/repos_config.dart';
import 'package:pubspec/pubspec.dart';

import 'common/utils.dart';

Future<void> checkoutLocal(DartReposOptions options, CliLogger logger) async {
  final checkout = options.repos;
  final results = <String, CheckoutResult>{};

  if (checkout.checkoutRoot?.isEmpty ?? true) {
    logger.warning('Invalid config:  Must have configured a root');
  } else {
    final dir = Directory(checkout.checkoutRoot!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    for (final entry in checkout.sources.entries) {
      final result = CheckoutResult();
      results[entry.key] = result;
      try {
        final key = entry.key;
        final value = entry.value;

        switch (value.mode ?? checkout.defaultMode) {
          case CheckoutMode.local:
            if (value.git != null) {
              final git = GitReference(
                value.git!.url,
                value.git!.ref ?? options.repos.defaultRef,
                value.git!.path,
              );
              await checkoutProject(
                key,
                git,
                dir,
                logger: logger.trace,
                result: result,
              );
            } else {
              result.message('No git configured');
            }
            break;
          default:
            result.message(
                'Not checking out (${(value.mode ?? checkout.defaultMode).name})');
        }
        result.success = true;
      } catch (e) {
        result.error('Unexpected: $e');
      }
    }
  }
  final isError = results.values.any((element) => !element.success);
  final anySuccess = results.values.any((element) => element.success);
  if (anySuccess) {
    logger.log('Successes: ');
    for (final value in results.entries) {
      if (value.value.success) {
        final ch = logger.child(value.key);
        value.value.messages.forEach(ch.log);
      }
    }
  }

  if (isError) {
    logger.log('There were some errors');
    for (final value in results.entries) {
      if (!value.value.success) {
        final ch = logger.child(value.key);
        value.value.messages.forEach(ch.child);
      }
    }
  }
}

void noop(str) {}

Future<CheckoutResult> checkoutProject(
  String projectName,
  GitReference gitReference,
  Directory checkoutDir, {
  LogFn logger = noop,
  CheckoutResult? result,
}) async {
  result ??= CheckoutResult();
  final folderName = gitUrlToFolderPath(gitReference.url);
  final subdir = checkoutDir.subdirs(folderName);
  if (!subdir.parent.existsSync()) {
    subdir.parent.createSync(recursive: true);
  }

  if (!subdir.existsSync()) {
    result.message('Cloning repo: ${gitReference.url}');

    final git = GitClient(subdir.parent.path, logger);
    // Check out!
    await git.clone(
      gitReference.url,
      into: subdir.path,
    );
  } else {
    if (!subdir.subdir('.git').existsSync()) {
      result.error('not a git repository');

      return result;
    } else {
      result.message('clone: complete');
    }
  }
  final git = GitClient(subdir.path, logger);

  /// CHECK ORIGIN REMOTE
  final remotes = await git.remotesList();
  if (remotes['origin'] != gitReference.url) {
    result.error(
      'wrong origin: expected ${gitReference.url} but got '
      '${remotes['origin']}',
    );
    return result;
  } else {
    result.message('origin: ${gitReference.url}');
  }

  /// CHECK TAG/BRANCH
  if (gitReference.ref != null) {
    Future<List<String>> currentCheckoutTags() async {
      final currentBranchName = await git.currentBranchName;

      final allTags = (currentBranchName == 'HEAD')
          ? await git.tagsForCurrentRevision
          : [currentBranchName];

      return allTags;
    }

    final expectedTag = gitReference.ref;

    var allTags = await currentCheckoutTags();
    if (!allTags.contains(gitReference.ref)) {
      /// Check to see if the branch exists

      var branchName = gitReference.ref!;
      if (!await git.hasBranch(branchName)) {
        await git.createBranch(branchName);
      } else {
        result.message(
          'branch: changing to $expectedTag (was $allTags)',
        );

        await git.checkout(ref: branchName);
        allTags = await currentCheckoutTags();
        if (!allTags.contains(expectedTag)) {
          result.error(
            'Branch change to $expectedTag failed:'
            ' Current branch/tag: $allTags',
          );
        }
      }
    } else {
      result.message(
        'branch: $expectedTag is checked out',
      );
    }
  }
  return result;
}

class CheckoutResult {
  CheckoutResult();

  bool success = false;
  final List<String> messages = [];

  void error(String message) {
    messages.add(message);
    success = false;
  }

  void message(String message) {
    messages.add(message);
  }
}
