/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:git_setup/screens.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDismissKey = 'setup_git_host_banner_dismissed';

/// Dismissible Home banner when remote git host is not configured.
class SetupGitHostBanner extends StatefulWidget {
  const SetupGitHostBanner({super.key});

  @override
  State<SetupGitHostBanner> createState() => _SetupGitHostBannerState();
}

class _SetupGitHostBannerState extends State<SetupGitHostBanner> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = pref.getBool(_kDismissKey) ?? false;
      _loaded = true;
    });
  }

  Future<void> _dismiss() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(_kDismissKey, true);
    if (!mounted) return;
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    final repo = context.watch<GitJournalRepo>();
    if (repo.remoteGitRepoConfigured) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.cloud_upload, color: theme.colorScheme.onSecondaryContainer),
        title: Text(
          context.loc.drawerSetup,
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _dismiss,
        ),
        onTap: () {
          Navigator.of(context).pushNamed(GitHostSetupScreen.routePath);
        },
      ),
    );
  }
}
