/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/folder_listing/view/folder_listing.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/screens/home_screen.dart';
import 'package:gitjournal/screens/tag_listing.dart';

/// Material 3 bottom destinations: All Notes, Folders, Tags, and optional New.
///
/// The optional 4th slot does **not** navigate — it toggles the note-creation
/// speed dial via [onNewNoteTap].
class MainNavBar extends StatelessWidget {
  /// When set, forces the highlighted destination (tests / missing route names).
  final int? selectedIndex;

  /// When non-null, shows a 4th "New" destination that calls this on tap.
  final VoidCallback? onNewNoteTap;

  const MainNavBar({
    super.key,
    this.selectedIndex,
    this.onNewNoteTap,
  });

  static const destinations = [
    HomeScreen.routePath,
    FolderListingScreen.routePath,
    TagListingScreen.routePath,
  ];

  static const indexHome = 0;
  static const indexFolders = 1;
  static const indexTags = 2;
  static const indexNew = 3;

  static int indexForRoute(String? route) {
    final i = destinations.indexOf(route ?? '');
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    // Page highlight is only among the three real destinations.
    final pageIndex = (selectedIndex ?? indexForRoute(route)).clamp(0, 2);

    final dests = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.notes_outlined),
        selectedIcon: const Icon(Icons.notes),
        label: context.loc.drawerAll,
      ),
      NavigationDestination(
        icon: const Icon(Icons.folder_outlined),
        selectedIcon: const Icon(Icons.folder),
        label: context.loc.drawerFolders,
      ),
      NavigationDestination(
        icon: const Icon(Icons.label_outline),
        selectedIcon: const Icon(Icons.label),
        label: context.loc.drawerTags,
      ),
      if (onNewNoteTap != null)
        const NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'New',
        ),
    ];

    return NavigationBar(
      selectedIndex: pageIndex,
      onDestinationSelected: (index) {
        if (onNewNoteTap != null && index == indexNew) {
          onNewNoteTap!();
          return;
        }
        if (index > 2) return;
        final to = destinations[index];
        if (to == route) return;
        Log.i('MainNavBar: $route -> $to');
        Navigator.of(context).pushReplacementNamed(to);
      },
      destinations: dests,
    );
  }
}
