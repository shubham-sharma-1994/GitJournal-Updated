/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:function_types/function_types.dart';
import 'package:gitjournal/editors/common_types.dart';
import 'package:gitjournal/l10n.dart';

/// Speed-dial FAB for creating Markdown / Checklist / Journal notes.
///
/// Controlled externally via [openCloseDial] so the nav-bar "New" slot can
/// toggle the same dial (scrim + staggered children from flutter_speed_dial).
class NewNoteSpeedDial extends StatelessWidget {
  final ValueNotifier<bool> openCloseDial;
  final Func1<EditorType, void> onPressed;

  const NewNoteSpeedDial({
    super.key,
    required this.openCloseDial,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SpeedDial(
      key: const ValueKey('FAB'),
      openCloseDial: openCloseDial,
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 10,
      spaceBetweenChildren: 8,
      overlayColor: Colors.black,
      overlayOpacity: 0.35,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      activeBackgroundColor: theme.colorScheme.secondaryContainer,
      activeForegroundColor: theme.colorScheme.onSecondaryContainer,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.checklist),
          label: context.loc.settingsEditorsChecklistEditor,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          onTap: () => onPressed(EditorType.Checklist),
        ),
        SpeedDialChild(
          child: const Icon(Icons.article),
          label: context.loc.settingsEditorsMarkdownEditor,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          onTap: () => onPressed(EditorType.Markdown),
        ),
        SpeedDialChild(
          child: const Icon(Icons.menu_book),
          label: context.loc.settingsEditorsJournalEditor,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          onTap: () => onPressed(EditorType.Journal),
        ),
      ],
    );
  }
}
