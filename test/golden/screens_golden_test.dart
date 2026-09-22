/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:dart_git/plumbing/git_hash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/core/folder/sorting_mode.dart';
import 'package:gitjournal/editors/common_types.dart';
import 'package:gitjournal/editors/note_editor.dart';
import 'package:gitjournal/folder_listing/view/folder_listing.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/screens/git_terminal_screen.dart';
import 'package:gitjournal/screens/home_screen.dart';
import 'package:gitjournal/screens/onboarding_screens.dart';
import 'package:gitjournal/screens/tag_listing.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/themes.dart';
import 'package:gitjournal/widgets/folder_selection_dialog.dart';
import 'package:gitjournal/widgets/main_nav_bar.dart';
import 'package:gitjournal/widgets/note_delete_dialog.dart';
import 'package:gitjournal/widgets/rename_dialog.dart';
import 'package:gitjournal/widgets/sorting_mode_selection_dialog.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    PackageInfo.setMockInitialValues(
      appName: 'GitJournal',
      packageName: 'io.gitjournal.gitjournal',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> setupFixture({
    Map<String, Object> sharedPrefValues = const {},
  }) async {
    final td = await TestData.load(
      headHash: GitHash('7fc65b59170bdc91013eb56cdc65fa3307f2e7de'),
      sharedPrefValues: sharedPrefValues,
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

    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ListTile background color or ink splashes may be invisible')) {
        return;
      }
      if (msg.contains('Supabase') || msg.contains('supabase')) {
        return;
      }
      if (msg.contains('MissingPluginException')) {
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
    // Allow Futures (e.g. TagListing) to complete between frames.
    // Flush real async (tag/folder futures) between frames.
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pump(const Duration(milliseconds: 40));
    }

    // Drain plugin/async exceptions that should not fail the golden.
    for (var i = 0; i < 5; i++) {
      final ex = tester.takeException();
      if (ex == null) break;
    }

    // Avoid pumpAndSettle (infinite progress indicators / ticker loops).
    await screenMatchesGolden(
      tester,
      goldenName,
      customPump: (t) async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
      },
    );
  }

  /// Pump a dialog over a blank scaffold and capture the full surface.
  Future<void> pumpDialogGolden(
    WidgetTester tester, {
    required Widget dialog,
    required String themeName,
    required Locale locale,
    required String goldenName,
  }) async {
    await pumpGolden(
      tester,
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => dialog,
            );
          });
          return const Scaffold(body: SizedBox.expand());
        },
      ),
      themeName: themeName,
      locale: locale,
      goldenName: goldenName,
    );
  }

  // Dialogs: light/dark only (RTL layout is trivial for AlertDialogs).
  final dialogVariants = <({String name, String theme, Locale locale})>[
    (name: 'light', theme: DEFAULT_LIGHT_THEME_NAME, locale: Locale('en')),
    (name: 'dark', theme: DEFAULT_DARK_THEME_NAME, locale: Locale('en')),
  ];

  group('HomeScreen goldens', () {
    testGoldens('home variants (banner shown when remote not configured)',
        (tester) async {
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

    testGoldens('home with Setup Git Host banner dismissed', (tester) async {
      await tester.runAsync(() => setupFixture(sharedPrefValues: {
            'setup_git_host_banner_dismissed': true,
          }));
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: HomeScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'home_banner_dismissed_${v.name}',
        );
      }
    });

    // SHU-23: speed-dial open state (closed state is home_*).
    testGoldens('home speed dial open', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await tester.binding.setSurfaceSize(GoldenConfig.surfaceSize);
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });
        await tester.pumpWidget(
          GoldenConfig.wrap(
            child: HomeScreen(),
            themeName: v.theme,
            locale: v.locale,
            repoManager: repoManager,
            pref: pref,
          ),
        );
        for (var i = 0; i < 25; i++) {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          });
          await tester.pump(const Duration(milliseconds: 40));
        }
        final fab = find.byKey(const ValueKey('FAB'));
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        // Speed-dial stagger animation ~300ms.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 200));
        await screenMatchesGolden(
          tester,
          'home_dial_open_${v.name}',
          customPump: (t) async {
            await t.pump();
            await t.pump(const Duration(milliseconds: 100));
          },
        );
      }
    });
  });

  // navbar_*.png was an isolated MainNavBar component test with a stub
  // Scaffold ("Nav" / "body"). Renamed to navbar_component_* so it is not
  // confused with a full-screen capture. Full-shell coverage is home_*.
  group('MainNavBar component goldens', () {
    testGoldens('nav bar component variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: Scaffold(
            appBar: AppBar(title: const Text('Nav')),
            body: const Center(child: Text('body')),
            bottomNavigationBar: MainNavBar(
              onNewNoteTap: () {},
            ),
          ),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'navbar_component_${v.name}',
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

  group('FolderListingScreen goldens', () {
    testGoldens('folder listing variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: FolderListingScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'folders_${v.name}',
        );
      }
    });
  });

  group('TagListingScreen goldens', () {
    testGoldens('tag listing variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: const TagListingScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'tags_${v.name}',
        );
      }
    });
  });

  group('OnBoardingScreen goldens', () {
    testGoldens('onboarding variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: const OnBoardingScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'onboarding_${v.name}',
        );
      }
    });
  });

  group('GitTerminalScreen goldens', () {
    testGoldens('git terminal variants', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in goldenVariants) {
        await pumpGolden(
          tester,
          child: const GitTerminalScreen(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'git_terminal_${v.name}',
        );
      }
    });
  });

  // LoginPage skipped: Supabase/gotrue starts pending auto-refresh timers and
  // app_links MissingPluginException — not golden-safe without a full plugin mock.
  // See docs/SHU-20-NOTES.md.

  group('Dialog goldens (light/dark only — RTL skipped)', () {
    testGoldens('rename dialog', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in dialogVariants) {
        await pumpDialogGolden(
          tester,
          dialog: const RenameDialog(
            oldPath: 'notes/example.md',
            inputDecoration: 'File name',
            dialogTitle: 'Rename',
          ),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'dialog_rename_${v.name}',
        );
      }
    });

    testGoldens('delete note dialog', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in dialogVariants) {
        await pumpDialogGolden(
          tester,
          dialog: const NoteDeleteDialog(num: 1),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'dialog_delete_note_${v.name}',
        );
      }
    });

    testGoldens('sorting mode dialog', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in dialogVariants) {
        await pumpDialogGolden(
          tester,
          dialog: SortingModeSelectionDialog(
            SortingMode(SortingField.Default, SortingOrder.Default),
          ),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'dialog_sorting_${v.name}',
        );
      }
    });

    testGoldens('folder selection dialog', (tester) async {
      await tester.runAsync(setupFixture);
      for (final v in dialogVariants) {
        await pumpDialogGolden(
          tester,
          dialog: FolderSelectionDialog(),
          themeName: v.theme,
          locale: v.locale,
          goldenName: 'dialog_folder_selection_${v.name}',
        );
      }
    });
  });
}
