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
  /// When set, forces the highlighted destination (needed when the route
  /// has no [RouteSettings.name], e.g. tests or nested pushes).
  final int? selectedIndex;

  const MainNavBar({super.key, this.selectedIndex});

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
    final selected = selectedIndex ?? indexForRoute(route);

    return NavigationBar(
      selectedIndex: selected.clamp(0, destinations.length - 1),
      onDestinationSelected: (index) {
        final to = destinations[index];
        if (to == route) return;
        // Also skip if we are already on this destination via forced index
        // and the named route matches the destination path when present.
        if (selectedIndex == index && (route == null || route == to)) {
          // still navigate if route name is missing so real navigation works
        }
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
