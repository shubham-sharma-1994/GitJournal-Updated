/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:dart_git/dart_git.dart';
import 'package:flutter/material.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/setup/git_https.dart';
import 'package:provider/provider.dart';

class GitTerminalScreen extends StatefulWidget {
  static const routePath = '/gitTerminal';

  const GitTerminalScreen({super.key});

  @override
  State<GitTerminalScreen> createState() => _GitTerminalScreenState();
}

class _GitTerminalScreenState extends State<GitTerminalScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_TermLine>[
    _TermLine(
      'GitJournal terminal — basic git commands only.\n'
      'Type "help" for the list. Working directory is the current journal.',
      kind: _Kind.sys,
    ),
  ];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run(String raw) async {
    final cmd = raw.trim();
    if (cmd.isEmpty) return;
    setState(() {
      _lines.add(_TermLine('\$ $cmd', kind: _Kind.in_));
      _busy = true;
    });
    _controller.clear();

    String out;
    try {
      out = await _dispatch(cmd);
    } catch (e, st) {
      Log.e('git terminal', ex: e, stacktrace: st);
      out = 'error: $e';
    }

    if (!mounted) return;
    setState(() {
      _lines.add(_TermLine(out.isEmpty ? '(no output)' : out, kind: _Kind.out));
      _busy = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  Future<String> _dispatch(String cmd) async {
    final repo = context.read<GitJournalRepo>();
    final path = repo.repoPath;
    final parts = _split(cmd);
    if (parts.isEmpty) return '';
    final name = parts.first;
    final args = parts.sublist(1);

    switch (name) {
      case 'help':
        return '''Supported commands:
  help
  pwd
  status          git status
  log [n]         recent commits (default 15)
  branch
  remote
  add [path]      stage path or "."
  commit -m MSG
  fetch
  pull
  push
  clone URL       HTTPS or SSH (uses saved token/keys)

Arbitrary shell is not available on Android.''';
      case 'pwd':
        return path;
      case 'git':
        if (args.isEmpty) return 'usage: git <command>';
        return _dispatch(args.join(' '));
      case 'status':
        return _status(path);
      case 'log':
        final n = args.isNotEmpty ? int.tryParse(args.first) ?? 15 : 15;
        return _log(path, n);
      case 'branch':
        return _branch(path);
      case 'remote':
        return _remote(path);
      case 'add':
        return _add(path, args.isEmpty ? '.' : args.first);
      case 'commit':
        return _commit(repo, args);
      case 'fetch':
      case 'pull':
      case 'push':
        await repo.syncNotes();
        return 'sync (fetch/merge/push) complete';
      case 'clone':
        if (args.isEmpty) return 'usage: clone <url>';
        return 'Use Setup Git Host for first-time clone.\n'
            'URL received: ${normalizeCloneUrl(args.first)}';
      case 'clear':
        _lines.clear();
        return '';
      default:
        return 'unknown command: $name\nType "help".';
    }
  }

  Future<String> _status(String path) async {
    final r = await GitAsyncRepository.load(path);
    final branch = await r.currentBranch();
    final changes = await r.numChangesToPush();
    return 'On branch $branch\nchanges to push: $changes';
  }

  Future<String> _log(String path, int n) async {
    final r = await GitAsyncRepository.load(path);
    try {
      final head = await r.headCommit();
      final first = head.message.split("\n").first;
      return '${head.hash}  $first';
    } catch (e) {
      return 'log failed: $e';
    }
  }

  Future<String> _branch(String path) async {
    final r = await GitAsyncRepository.load(path);
    final cur = await r.currentBranch();
    final all = await r.branches();
    return all.map((b) => (b == cur ? '* ' : '  ') + b).join('\n');
  }

  Future<String> _remote(String path) async {
    final r = GitRepository.load(path);
    try {
      final remotes = r.config.remotes;
      if (remotes.isEmpty) return '(no remotes)';
      return remotes.map((rm) => '${rm.name}\t${rm.url}').join('\n');
    } finally {
      r.close();
    }
  }

  Future<String> _add(String path, String spec) async {
    final r = await GitAsyncRepository.load(path);
    await r.add(spec);
    return 'staged $spec';
  }

  Future<String> _commit(GitJournalRepo repo, List<String> args) async {
    String msg = 'update from GitJournal terminal';
    final mi = args.indexOf('-m');
    if (mi >= 0 && mi + 1 < args.length) {
      msg = args.sublist(mi + 1).join(' ').replaceAll('"', '');
    }
    final r = await GitAsyncRepository.load(repo.repoPath);
    await r.add('.');
    await r.commit(
      message: msg,
      author: GitAuthor(
        name: repo.gitConfig.gitAuthor,
        email: repo.gitConfig.gitAuthorEmail,
      ),
    );
    return 'committed: $msg';
  }

  List<String> _split(String s) {
    final out = <String>[];
    final buf = StringBuffer();
    var q = false;
    for (final ch in s.split('')) {
      if (ch == '"') {
        q = !q;
        continue;
      }
      if (ch == ' ' && !q) {
        if (buf.isNotEmpty) {
          out.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Git Terminal')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final line = _lines[i];
                Color c;
                switch (line.kind) {
                  case _Kind.in_:
                    c = theme.colorScheme.primary;
                    break;
                  case _Kind.sys:
                    c = theme.hintColor;
                    break;
                  case _Kind.out:
                    c = theme.colorScheme.onSurface;
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: c,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_busy,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'git status',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: _run,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : () => _run(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Kind { in_, out, sys }

class _TermLine {
  final String text;
  final _Kind kind;
  _TermLine(this.text, {required this.kind});
}
