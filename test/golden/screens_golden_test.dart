/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:dart_git/plumbing/git_hash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/editors/common_types.dart';
import 'package:gitjournal/editors/note_editor.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/screens/home_screen.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:gitjournal/widgets/app_drawer.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib.dart';
import 'golden_config.dart';

void main() {
  late GitJournalRepo repo;
  late RepositoryManager repoManager;
  late SharedPreferences pref;

  setUpAll(() async {
    await gjSetupAllTests();
    await GoldenConfig.loadFonts();
    await GoldenConfig.initHive();
  });

  Future<void> setupFixture() async {
    final td = await TestData.load(
      headHash: GitHash('7fc65b59170bdc91013eb56cdc65fa3307f2e7de'),
    );
    repo = td.repo;
    repoManager = td.repoManager;
    pref = td.pref;
    AppConfig.instance.load(pref);
  }

  Future<void> pumpGolden(
    WidgetTester tester, {
    required Widget child,
    required String themeName,
    required Locale locale,
    required String goldenName,
  }) async {
    await tester.binding.setSurfaceSize(GoldenConfig.surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    // Drawer ListTile-under-ColoredBox asserts are known in this codebase;
    // do not fail the golden run on them.
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ListTile background color or ink splashes may be invisible')) {
        return;
      }
      oldOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = oldOnError;
    });

    await tester.pumpWidget(
      GoldenConfig.wrap(
        child: child,
        themeName: themeName,
        locale: locale,
        repoManager: repoManager,
        pref: pref,
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await screenMatchesGolden(tester, goldenName);
  }

  group('HomeScreen goldens', () {
    testGoldens('home variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: HomeScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'home_${v.name}',
        );
      }
    });
  });

  group('AppDrawer goldens', () {
    testGoldens('drawer variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        // Capture drawer as a full-screen surface (not Scaffold.drawer)
        // to avoid open-drawer timing and keep the baseline stable.
        await pumpGolden(
          tester,
          child: AppDrawer(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'drawer_${v.name}',
        );
      }
    });
  });

  group('SettingsScreen goldens', () {
    testGoldens('settings variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: SettingsScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'settings_${v.name}',
        );
      }
    });
  });

  group('NoteEditor goldens', () {
    testGoldens('editor variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        final editor = NoteEditor.newNote(
          repo.rootFolder,
          repo.rootFolder,
          EditorType.Markdown,
          existingText: 'Golden baseline note body',
          existingImages: const [],
        );
        await pumpGolden(
          tester,
          child: editor,
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'editor_${v.name}',
        );
      }
    });
  });
}
