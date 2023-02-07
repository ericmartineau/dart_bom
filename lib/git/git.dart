/*
 * Copyright (c) 2016-present Invertase Limited & Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import 'dart:io';

import 'package:dart_bom/common/logging.dart';
import 'package:path/path.dart';

import '../common/io.dart';

enum TagReleaseType {
  all,
  prerelease,
  stable,
}

class GitClient {
  final String workingDirectory;
  final CliLogger logger;

  GitClient(this.workingDirectory, [CliLogger? logger])
      : logger = logger ?? CliLogger();

  /// Generate a filter pattern for a package name, useful for listing tags for a
  /// package.
  String tagFilterPattern(
    String packageName,
    TagReleaseType tagReleaseType, {
    String preid = 'dev',
    String prefix = 'v',
  }) {
    return tagReleaseType == TagReleaseType.prerelease
        ? '$packageName-$prefix*-$preid.*'
        : '$packageName-$prefix*';
  }

  /// Generate a git tag string for the specified package name and version.
  String tagForPackageVersion(
    String packageName,
    String packageVersion, {
    String prefix = 'v',
  }) {
    return '$packageName-$prefix$packageVersion';
  }

  /// Execute a `git` CLI command with arguments.
  Future<ProcessResult> executeCommand({
    required List<String> arguments,
    bool throwOnExitCodeError = true,
  }) async {
    const executable = 'git';

    logger.trace(
      '[GIT] Executing command `$executable ${arguments.join(' ')}` '
      'in directory `$workingDirectory`.',
    );

    final processResult = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    if (throwOnExitCodeError && processResult.exitCode != 0) {
      throw ProcessException(
        executable,
        arguments,
        'Melos: Failed executing a git command: '
        '${processResult.stdout} ${processResult.stderr}',
      );
    }

    return processResult;
  }

  /// Check a tag exists.
  Future<bool> tagExists(String tag) async {
    final processResult = await executeCommand(
      arguments: ['tag', '-l', tag],
    );
    return (processResult.stdout as String).contains(tag);
  }

  /// Check a tag exists.
  Future<List<Branch>> get allBranches async {
    final processResult = await executeCommand(
      arguments: ['branch', '-a'],
    );
    return (processResult.stdout as List)
        .map((l) => Branch.of(l.toString()))
        .toList();
  }

  Future<bool> hasBranch(String branchName) async {
    final branches = await allBranches;
    return branches.any((branch) =>
        branch.branchName.toLowerCase() == branchName.toLowerCase());
  }

  /// Creates a new branch
  Future<void> createBranch(String branchName) async {
    await executeCommand(
      arguments: [
        'checkout',
        '-b',
        branchName,
      ],
    );
  }

  /// Create a tag, if it does not already exist.
  ///
  /// Returns true if tag was successfully created.
  Future<bool> tagCreate(
    String tag,
    String message, {
    String? commitId,
  }) async {
    if (await tagExists(
      tag,
    )) {
      return false;
    }

    final arguments = commitId != null && commitId.isNotEmpty
        ? ['tag', '-a', tag, commitId, '-m', message]
        : ['tag', '-a', tag, '-m', message];

    await executeCommand(
      arguments: arguments,
      throwOnExitCodeError: false,
    );

    return tagExists(
      tag,
    );
  }

  /// Stage files matching the specified file pattern for committing.
  Future<void> add(String filePattern) async {
    final arguments = ['add', filePattern];
    await executeCommand(
      arguments: arguments,
    );
  }

  Future<void> clone(
    String repository, {
    required String into,
  }) async {
    final arguments = ['clone', repository, into];
    await executeCommand(
      arguments: arguments,
    );
  }

  Future<void> checkout({
    required String ref,
  }) async {
    final arguments = ['checkout', ref];
    await executeCommand(
      arguments: arguments,
    );
  }

  /// Commit any staged changes with a specific git message.
  Future<void> commit(
    String message,
  ) async {
    final arguments = ['commit', '-m', message];
    await executeCommand(
      arguments: arguments,
    );
  }

  Future<List<String>> tagsForRevision(
    String revision,
  ) async {
    final arguments = ['tag', '--points-at', revision];
    final processResult = await executeCommand(
      arguments: arguments,
    );

    final rawResult = processResult.stdout as String;
    return rawResult
        .trim()
        .split(r'\n')
        .where((element) => element.isNotEmpty)
        .toList();
  }

  Future<List<String>> get tagsForCurrentRevision async {
    final currentRev = currentRevision();
    return tagsForRevision(currentRev);
  }

  String currentRevision() {
    final rev = readTextFile(join(workingDirectory, '.git', 'HEAD')).trim();
    return rev;
  }

  /// Returns the current branch name of the local git repository.
  Future<String> get currentBranchName async {
    final arguments = ['rev-parse', '--abbrev-ref', 'HEAD'];
    final processResult = await executeCommand(
      arguments: arguments,
    );
    return (processResult.stdout as String).trim();
  }

  /// Fetches updates for the default remote in the repository.
  Future<void> remoteUpdate() async {
    final arguments = ['remote', 'update'];
    await executeCommand(
      arguments: arguments,
    );
  }

  /// Fetches updates for the default remote in the repository.
  Future<Map<String, String>> remotesList() async {
    final arguments = ['remote', '-v'];
    final processResult = await executeCommand(
      arguments: arguments,
    );
    final lines = (processResult.stdout as String)
        .trim()
        .split('\n')
        .where((l) => l.contains('(fetch)'))
        .map((l) => l.split(RegExp(r'\s+')))
        .where((element) => element.length > 1)
        .toList();
    return {
      for (final line in lines) line[0]: line[1],
    };
  }

  /// Determine if the local git repository is behind on commits from it's remote
  /// branch.
  Future<bool> isBehindUpstream({
    String remote = 'origin',
    String? branch,
  }) async {
    await remoteUpdate();

    final localBranch = branch ?? await currentBranchName;
    final remoteBranch = '$remote/$localBranch';
    final arguments = [
      'rev-list',
      '--left-right',
      '--count',
      '$remoteBranch...$localBranch',
    ];

    final processResult = await executeCommand(
      arguments: arguments,
    );
    final leftRightCounts = (processResult.stdout as String)
        .split('\t')
        .map<int>(int.parse)
        .toList();
    final behindCount = leftRightCounts[0];
    final aheadCount = leftRightCounts[1];
    final isBehind = behindCount > 0;

    logger.trace(
      '[GIT] Local branch `$localBranch` is behind remote branch `$remoteBranch` '
      'by $behindCount commit(s) and ahead by $aheadCount.',
    );

    return isBehind;
  }
}

class Branch {
  final String branchName;
  final String? remote;

  const Branch({required this.branchName, this.remote});
  factory Branch.of(String input) {
    if (input.startsWith("remotes/")) {
      var parts = input.split("/");
      return Branch(branchName: parts.sublist(2).join("/"), remote: parts[1]);
    } else {
      return Branch(branchName: input);
    }
  }
}
