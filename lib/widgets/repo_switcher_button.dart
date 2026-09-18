/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:git_setup/screens.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/screens/error_screen.dart';
import 'package:gitjournal/screens/home_screen.dart';
import 'package:provider/provider.dart';

/// AppBar control: current repo name + menu to switch / add / long-press delete.
class RepoSwitcherButton extends StatelessWidget {
  const RepoSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final repoManager = context.watch<RepositoryManager>();
    final currentName = repoManager.repoFolderName(repoManager.currentId);

    return PopupMenuButton<String>(
      tooltip: currentName,
      offset: const Offset(0, 40),
      onSelected: (value) async {
        if (value == '__add__') {
          var _ = await Navigator.pushNamed(
            context,
            GitHostSetupScreen.routePath,
          );
          return;
        }
        if (value == repoManager.currentId) return;
        try {
          await repoManager.setCurrentRepo(value);
        } catch (_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            ErrorScreen.routePath,
            (r) => true,
          );
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          HomeScreen.routePath,
          (r) => true,
        );
      },
      itemBuilder: (context) {
        return [
          for (final id in repoManager.repoIds)
            PopupMenuItem<String>(
              value: id,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.menu_book,
                  color: id == repoManager.currentId
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                ),
                title: Text(repoManager.repoFolderName(id)),
                onLongPress: () async {
                  Navigator.pop(context);
                  final name = repoManager.repoFolderName(id);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(context.loc.settingsDeleteRepo),
                      content: Text('Delete "$name"? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(context.loc.settingsCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(context.loc.settingsDeleteRepo),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await repoManager.deleteRepo(id);
                  }
                },
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__add__',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add),
              title: Text(context.loc.drawerAddRepo),
            ),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
