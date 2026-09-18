/*
 * SPDX-FileCopyrightText: 2023 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:gitjournal/app_router.dart';
import 'package:gitjournal/change_notifiers.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/themes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetbook/widgetbook.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pref = await SharedPreferences.getInstance();

  AppConfig.instance.load(pref);

  final appConfig = AppConfig.instance;
  Log.i("AppConfig ${appConfig.toMap()}");

  final gitBaseDirectory = (await getTemporaryDirectory()).path;
  final cacheDir = (await getTemporaryDirectory()).path;

  final repoManager = RepositoryManager(
    gitBaseDir: gitBaseDirectory,
    cacheDir: cacheDir,
    pref: pref,
  );
  await repoManager.buildActiveRepository();
  final repo = repoManager.currentRepo!;
  final settings = repo.settings;
  final storageConfig = repo.storageConfig;
  final appRouter = AppRouter(
    settings: settings,
    appConfig: appConfig,
    storageConfig: storageConfig,
  );

  Widget wrapDeps(Widget child) {
    return GitJournalChangeNotifiers(
      repoManager: repoManager,
      appConfig: appConfig,
      pref: pref,
      child: child,
    );
  }

  runApp(
    Widgetbook.material(
      directories: [
        WidgetbookFolder(
          name: 'Router',
          children: [
            WidgetbookComponent(
              name: 'Named routes',
              useCases: [
                for (final routeName in AppRoute.all)
                  WidgetbookUseCase(
                    name: routeName,
                    builder: (context) {
                      final screen = appRouter.screenForRoute(
                        routeName,
                        repo,
                        storageConfig,
                        '',
                        [],
                        () {},
                      );
                      return wrapDeps(screen ?? const SizedBox.shrink());
                    },
                  ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'Smoke',
          children: [
            WidgetbookComponent(
              name: 'Material',
              useCases: [
                WidgetbookUseCase(
                  name: 'Hello',
                  builder: (context) => wrapDeps(
                    const Scaffold(
                      body: Center(child: Text('GitJournal Widgetbook')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: Themes.fromName(DEFAULT_LIGHT_THEME_NAME),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: Themes.fromName(DEFAULT_DARK_THEME_NAME),
            ),
          ],
        ),
        LocalizationAddon(
          locales: gitJournalSupportedLocales,
          localizationsDelegates: gitJournalLocalizationDelegates,
          initialLocale: const Locale('en'),
        ),
        ViewportAddon([
          IosViewports.iPhone13,
          IosViewports.iPhoneSE,
          AndroidViewports.samsungGalaxyS20,
        ]),
      ],
    ),
  );
}
