/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:gitjournal/widgets/repo_switcher_button.dart';
import 'package:gitjournal/widgets/main_app_bar_actions.dart';
import 'package:gitjournal/widgets/main_nav_bar.dart';
import 'package:gitjournal/core/folder/flattened_filtered_notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder_fs.dart';
import 'package:gitjournal/core/markdown/md_yaml_note_serializer.dart';
import 'package:gitjournal/core/note.dart';
import 'package:gitjournal/core/views/inline_tags_view.dart';
import 'package:gitjournal/folder_views/folder_view.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/widgets/future_builder_with_progress.dart';
import 'package:gitjournal/widgets/pro_overlay.dart';
import 'package:provider/provider.dart';

class TagListingScreen extends StatefulWidget {
  static const routePath = '/tags';

  const TagListingScreen({super.key});

  @override
  State<TagListingScreen> createState() => _TagListingScreenState();
}

class _TagListingScreenState extends State<TagListingScreen> {
  Future<SplayTreeSet<String>>? _tagsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load once per dependency change (repo / tags provider).
    _tagsFuture ??= _loadTags(context);
  }

  Future<SplayTreeSet<String>> _loadTags(BuildContext context) async {
    final rootFolder = context.read<NotesFolderFS>();
    final inlineTagsView = InlineTagsProvider.of(context);
    final allTags = await rootFolder.getNoteTagsRecursively(inlineTagsView);
    return SplayTreeSet<String>.from(allTags);
  }

  @override
  Widget build(BuildContext context) {
    // Always paint Scaffold so loading is not a black full-screen spinner
    // and the Tags nav destination stays selected.
    return Scaffold(
      appBar: AppBar(
        title: const RepoSwitcherButton(),
        actions: mainAppBarActions(context),
      ),
      body: FutureBuilder<SplayTreeSet<String>>(
        future: _tagsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final allTags = snapshot.data ?? SplayTreeSet<String>();
          if (allTags.isEmpty) {
            return Center(
              child: Text(
                context.loc.screensTagsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[350],
                ),
              ),
            );
          }
          return Scrollbar(
            child: ProOverlay(
              child: ListView(
                children: [
                  for (final tag in allTags) _buildTagTile(context, tag),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const MainNavBar(selectedIndex: MainNavBar.indexTags),
    );
  }

  Widget _buildTagTile(BuildContext context, String tag) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.displayLarge!.color;

    return ListTile(
      leading: Icon(Icons.label, color: titleColor),
      title: Text(tag),
      onTap: () {
        final route = MaterialPageRoute(
          builder: (context) => FutureBuilderWithProgress(
            future: _tagFolderView(context, tag),
          ),
          settings: const RouteSettings(name: TagListingScreen.routePath),
        );
        Navigator.push(context, route);
      },
    );
  }
}

Future<FolderView> _tagFolderView(BuildContext context, String tag) async {
  var rootFolder = context.read<NotesFolderFS>();
  var inlineTagsView = InlineTagsProvider.of(context);

  var folder = await FlattenedFilteredNotesFolder.load(
    rootFolder,
    filter: (Note n) async {
      if (n.tags.contains(tag)) {
        return true;
      }

      var inlineTags = await inlineTagsView.fetch(n);
      if (inlineTags.contains(tag)) {
        return true;
      }

      return false;
    },
    title: tag,
  );

  final propNames = NoteSerializationSettings();
  return FolderView(
    notesFolder: folder,
    newNoteExtraProps: {
      propNames.tagsKey: [tag],
    },
  );
}
