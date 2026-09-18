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

/// Material 3 bottom destinations for the three primary app screens.
class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key});

  static const destinations = [
    HomeScreen.routePath,
    FolderListingScreen.routePath,
    TagListingScreen.routePath,
  ];

  static int indexForRoute(String? route) {
    final i = destinations.indexOf(route ?? '');
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    final selected = indexForRoute(route);

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
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
