/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/design/tokens/spacing_tokens.dart';
import 'package:function_types/function_types.dart';
import 'package:gitjournal/editors/common_types.dart';

// FIXME: Remove note_editor import!!

class NewNoteNavBar extends StatelessWidget {
  final Func1<EditorType, void> onPressed;

  const NewNoteNavBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).bottomAppBarTheme.color,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(spacingXs),
            child: IconButton(
              icon: Icon(Icons.checklist),
              onPressed: () => onPressed(EditorType.Checklist),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(spacingXs),
            child: IconButton(
              icon: Icon(Icons.article),
              onPressed: () => onPressed(EditorType.Markdown),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(spacingXs),
            child: IconButton(
              icon: Icon(Icons.menu_book),
              onPressed: () => onPressed(EditorType.Journal),
            ),
          ),
        ],
      ),
    );
  }
}
