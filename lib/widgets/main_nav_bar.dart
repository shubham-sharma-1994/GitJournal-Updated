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

/// Material 3 bottom destinations: All Notes, Folders, Tags.
///
/// Note creation is handled by the FAB speed dial on Home — not a nav slot.
class MainNavBar extends StatelessWidget {
  /// When set, forces the highlighted destination (tests / missing route names).
  final int? selectedIndex;

  const MainNavBar({
    super.key,
    this.selectedIndex,
  });

  static const destinations = [
    HomeScreen.routePath,
    FolderListingScreen.routePath,
    TagListingScreen.routePath,
  ];

  static const indexHome = 0;
  static const indexFolders = 1;
  static const indexTags = 2;

  static int indexForRoute(String? route) {
    final i = destinations.indexOf(route ?? '');
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    final selected = (selectedIndex ?? indexForRoute(route)).clamp(0, 2);

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index > 2) return;
        final to = destinations[index];
        if (to == route) return;
        Log.i('MainNavBar: $route -> $to');
        Navigator.of(context).pushReplacementNamed(to);
      },
      destinations: [
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
      ],
    );
  }
}
