/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/account/login_screen.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:provider/provider.dart';

/// Shared AppBar trailing actions for the three main destinations.
List<Widget> mainAppBarActions(BuildContext context) {
  final appConfig = context.watch<AppConfig>();
  return [
    if (appConfig.experimentalAccounts)
      IconButton(
        icon: const Icon(Icons.person_outline),
        tooltip: 'Login',
        onPressed: () {
          Navigator.of(context).pushNamed(LoginPage.routePath);
        },
      ),
    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
      onPressed: () {
        Navigator.of(context).pushNamed(SettingsScreen.routePath);
      },
    ),
  ];
}
