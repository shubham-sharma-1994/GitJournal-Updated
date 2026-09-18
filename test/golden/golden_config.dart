/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gitjournal/change_notifiers.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/themes.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared golden setup: real app themes + localization + Hive for views.
class GoldenConfig {
  static const surfaceSize = Size(390, 844);
  static Directory? _hiveDir;

  static Future<void> loadFonts() async {
    await loadAppFonts();
  }

  static Future<void> initHive() async {
    _hiveDir ??= Directory.systemTemp.createTempSync('gj_hive_golden_');
    Hive.init(_hiveDir!.path);
  }

  static Widget wrap({
    required Widget child,
    required String themeName,
    required Locale locale,
    required RepositoryManager repoManager,
    required SharedPreferences pref,
    AppConfig? appConfig,
  }) {
    final config = appConfig ?? AppConfig.instance;
    return GitJournalChangeNotifiers(
      repoManager: repoManager,
      appConfig: config,
      pref: pref,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Themes.fromName(themeName),
        locale: locale,
        localizationsDelegates: gitJournalLocalizationDelegates,
        supportedLocales: [
          ...gitJournalSupportedLocales,
          const Locale('fa'),
        ],
        home: child,
      ),
    );
  }
}

/// Variants used by every golden suite: light, dark, Farsi/RTL.
const goldenVariants = <({String name, String theme, Locale locale})>[
  (name: 'light', theme: DEFAULT_LIGHT_THEME_NAME, locale: Locale('en')),
  (name: 'dark', theme: DEFAULT_DARK_THEME_NAME, locale: Locale('en')),
  (name: 'fa_rtl', theme: DEFAULT_LIGHT_THEME_NAME, locale: Locale('fa')),
];
