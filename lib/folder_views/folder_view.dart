/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/design/tokens/spacing_tokens.dart';
import 'package:gitjournal/analytics/analytics.dart';
import 'package:gitjournal/app_router.dart';
import 'package:gitjournal/core/folder/filtered_notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder_fs.dart';
import 'package:gitjournal/core/folder/sorted_notes_folder.dart';
import 'package:gitjournal/core/folder/sorting_mode.dart';
import 'package:gitjournal/core/markdown/md_yaml_doc_codec.dart';
import 'package:gitjournal/core/note.dart';
import 'package:gitjournal/editors/common_types.dart';
import 'package:gitjournal/editors/note_editor.dart';
import 'package:gitjournal/folder_views/common.dart';
import 'package:gitjournal/folder_views/folder_view_configuration_dialog.dart';
import 'package:gitjournal/folder_views/folder_view_selection_dialog.dart';
import 'package:gitjournal/folder_views/standard_view.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/utils/utils.dart';
import 'package:gitjournal/widgets/main_nav_bar.dart';
import 'package:gitjournal/widgets/main_app_bar_actions.dart';
import 'package:gitjournal/widgets/repo_switcher_button.dart';
import 'package:gitjournal/widgets/setup_git_host_banner.dart';
import 'package:gitjournal/widgets/folder_selection_dialog.dart';
import 'package:gitjournal/widgets/new_note_speed_dial.dart';
import 'package:gitjournal/widgets/note_delete_dialog.dart';
import 'package:gitjournal/widgets/note_search_delegate.dart';
import 'package:gitjournal/widgets/sorting_mode_selection_dialog.dart';
import 'package:gitjournal/widgets/sync_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum DropDownChoices {
  SortingOptions,
  ViewOptions,
}

enum NoteSelectedExtraActions {
  MoveToFolder,
}

class FolderView extends StatefulWidget {
  final NotesFolder notesFolder;
  final Map<String, dynamic> newNoteExtraProps;

  const FolderView({
    required this.notesFolder,
    this.newNoteExtraProps = const {},
  });

  @override
  _FolderViewState createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  SortedNotesFolder? _sortedNotesFolder;
  SortedNotesFolder? _pinnedNotesFolder;
  FolderViewType _viewType = FolderViewType.Standard;

  var _headerType = StandardViewHeader.TitleGenerated;
  bool _showSummary = true;

  var _selectedNotes = <Note>[];
  bool get inSelectionMode => _selectedNotes.isNotEmpty;

  /// Controls the FAB speed dial open state.
  final ValueNotifier<bool> _dialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    _viewType = widget.notesFolder.config.defaultView.toFolderViewType();
    _showSummary = widget.notesFolder.config.showNoteSummary;
    _headerType = widget.notesFolder.config.viewHeader;

    var otherNotesFolder = SortedNotesFolder(
      folder: await FilteredNotesFolder.load(
        widget.notesFolder,
        title: context.loc.widgetsFolderViewPinned,
        filter: (Note note) async => !note.pinned,
      ),
      sortingMode: widget.notesFolder.config.sortingMode,
    );

    var pinnedFolder = SortedNotesFolder(
      folder: await FilteredNotesFolder.load(
        widget.notesFolder,
        title: context.loc.widgetsFolderViewPinned,
        filter: (Note note) async => note.pinned,
      ),
      sortingMode: widget.notesFolder.config.sortingMode,
    );

    setState(() {
      _sortedNotesFolder = otherNotesFolder;
      _pinnedNotesFolder = pinnedFolder;
    });
  }

  @override
  void dispose() {
    _sortedNotesFolder?.dispose();
    _pinnedNotesFolder?.dispose();
    _dialOpen.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(FolderView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.notesFolder != widget.notesFolder) {
      _init();
    }
  }

  Widget _buildBody(BuildContext context) {
    if (_sortedNotesFolder == null) {
      return Container();
    }
    var title = widget.notesFolder.publicName(context);
    if (inSelectionMode) {
      title = NumberFormat.compact().format(_selectedNotes.length);
    }

    var folderView = buildFolderView(
      viewType: _viewType,
      folder: _sortedNotesFolder!,
      emptyText: context.loc.screensFolderViewEmpty,
      header: _headerType,
      showSummary: _showSummary,
      noteTapped: _noteTapped,
      noteLongPressed: _noteLongPress,
      isNoteSelected: (n) => _selectedNotes.contains(n),
    );

    Widget pinnedFolderView = const SizedBox();
    if (_pinnedNotesFolder != null) {
      pinnedFolderView = buildFolderView(
        viewType: _viewType,
        folder: _pinnedNotesFolder!,
        emptyText: null,
        header: _headerType,
        showSummary: _showSummary,
        noteTapped: _noteTapped,
        noteLongPressed: _noteLongPress,
        isNoteSelected: (n) => _selectedNotes.contains(n),
      );
    }

    var settings = context.watch<Settings>();

    // Keep list clear of the speed-dial FAB.
    folderView = SliverPadding(
      sliver: folderView,
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, spacingXl + spacingMd),
    );

    var backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _resetSelection,
    );

    var havePinnedNotes =
        _pinnedNotesFolder != null ? !_pinnedNotesFolder!.isEmpty : false;

    // Single CustomScrollView (not NestedScrollView) so the list only
    // scrolls when content overflows — empty / short lists stay fixed.
    final slivers = <Widget>[
      SliverAppBar(
        pinned: true,
        floating: true,
        title: inSelectionMode ? Text(title) : const RepoSwitcherButton(),
        leading: inSelectionMode ? backButton : null,
        actions: inSelectionMode
            ? _buildInSelectionNoteActions()
            : [
                ..._buildNoteActions(),
                ...mainAppBarActions(context),
              ],
        forceElevated: true,
      ),
      const SliverToBoxAdapter(child: SetupGitHostBanner()),
      if (havePinnedNotes)
        _SliverHeader(text: context.loc.widgetsFolderViewPinned),
      if (havePinnedNotes) pinnedFolderView,
      if (havePinnedNotes)
        _SliverHeader(text: context.loc.widgetsFolderViewOthers),
      folderView,
    ];

    final view = CustomScrollView(
      // Clamping only: list is not scrollable when content fits (empty /
      // short lists stay fixed). Sync remains available via the app-bar button.
      physics: const ClampingScrollPhysics(),
      slivers: slivers,
    );

    if (settings.remoteSyncFrequency == RemoteSyncFrequency.Manual) {
      return Scrollbar(child: view);
    }
    return RefreshIndicator(
      onRefresh: () => syncRepo(context),
      child: Scrollbar(child: view),
    );
  }

  void _noteLongPress(Note note) {
    var i = _selectedNotes.indexOf(note);
    if (i != -1) {
      setState(() {
        _selectedNotes.removeAt(i);
      });
    } else {
      setState(() {
        _selectedNotes.add(note);
      });
    }
  }

  void _noteTapped(Note note) {
    if (!inSelectionMode) {
      openNoteEditor(context, note, widget.notesFolder);
      return;
    }

    var i = _selectedNotes.indexOf(note);
    if (i != -1) {
      setState(() {
        _selectedNotes.removeAt(i);
      });
    } else {
      setState(() {
        _selectedNotes.add(note);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note creation: FAB speed dial only (no duplicate "New" nav slot).
    Widget? bottom;
    if (!inSelectionMode) {
      bottom = const MainNavBar(selectedIndex: MainNavBar.indexHome);
    }

    return Scaffold(
      body: Builder(builder: _buildBody),
      extendBody: false,
      floatingActionButton: inSelectionMode
          ? null
          : NewNoteSpeedDial(
              openCloseDial: _dialOpen,
              onPressed: _newPost,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bottom,
    );
  }

  Future<void> _newPost(EditorType editorType) async {
    var settings = context.read<Settings>();
    var rootFolder = context.read<NotesFolderFS>();

    var folder = widget.notesFolder;
    var fsFolder = folder.fsFolder as NotesFolderFS;
    var isVirtualFolder = folder.name != folder.fsFolder!.name;

    if (isVirtualFolder) {
      fsFolder = getFolderForEditor(settings, rootFolder, editorType);
    }

    if (editorType == EditorType.Journal) {
      if (settings.journalEditordefaultNewNoteFolderSpec.isNotEmpty) {
        var spec = settings.journalEditordefaultNewNoteFolderSpec;
        fsFolder = rootFolder.getFolderWithSpec(spec) ?? rootFolder;

        if (!isVirtualFolder) {
          showSnackbar(
            context,
            context.loc.settingsEditorsJournalDefaultFolderSelect(spec),
          );
        }
      }

      if (settings.journalEditorSingleNote) {
        var note = await getTodayJournalEntry(fsFolder.rootFolder);
        if (note != null) {
          return openNoteEditor(
            context,
            note,
            fsFolder,
            editMode: true,
          );
        }
      }
    }

    var routeType =
        SettingsEditorType.fromEditorType(editorType).toInternalString();

    var extraProps = Map<String, dynamic>.from(widget.newNoteExtraProps);
    if (settings.customMetaData.isNotEmpty) {
      var map = MarkdownYAMLCodec.parseYamlText(settings.customMetaData);
      map.forEach((key, val) {
        extraProps[key] = val;
      });
    }
    var route = newNoteRoute(
      NoteEditor.newNote(
        fsFolder,
        widget.notesFolder,
        editorType,
        newNoteExtraProps: extraProps,
        existingText: "",
        existingImages: const [],
      ),
      AppRoute.NewNotePrefix + routeType,
    );
    await Navigator.push(context, route);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }


  Future<void> _sortButtonPressed() async {
    if (_sortedNotesFolder == null) {
      return;
    }
    var newSortingMode = await showDialog<SortingMode>(
      context: context,
      builder: (BuildContext context) =>
          SortingModeSelectionDialog(_sortedNotesFolder!.sortingMode),
    );

    if (newSortingMode != null) {
      var folderConfig = _sortedNotesFolder!.config;
      folderConfig.sortingField = newSortingMode.field;
      folderConfig.sortingOrder = newSortingMode.order;
      folderConfig.save();

      setState(() {
        _sortedNotesFolder!.changeSortingMode(newSortingMode);
      });
    }
  }

  Future<void> _configureViewButtonPressed() async {
    await showDialog<SortingMode>(
      context: context,
      builder: _viewDialog,
    );

    setState(() {});
  }

  Widget _viewDialog(BuildContext context) {
    void headerTypeChanged(StandardViewHeader? newHeader) {
      if (newHeader == null) {
        return;
      }
      setState(() {
        _headerType = newHeader;
      });

      var folderConfig = _sortedNotesFolder!.config;
      folderConfig.viewHeader = _headerType;
      folderConfig.save();
    }

    void summaryChanged(bool newVal) {
      setState(() {
        _showSummary = newVal;
      });

      var folderConfig = _sortedNotesFolder!.config;
      folderConfig.showNoteSummary = newVal;
      folderConfig.save();
    }

    return FolderViewConfigurationDialog(
      headerType: _headerType,
      showSummary: _showSummary,
      onHeaderTypeChanged: headerTypeChanged,
      onShowSummaryChanged: summaryChanged,
    );
  }

  Future<void> _folderViewChooserSelected() async {
    var newViewType = await showDialog<FolderViewType>(
      context: context,
      builder: (BuildContext context) {
        return FolderViewSelectionDialog(
          viewType: _viewType,
          onViewChange: (vt) => Navigator.of(context).pop(vt),
        );
      },
    );

    if (newViewType != null) {
      setState(() {
        _viewType = newViewType;
      });

      var folderConfig = widget.notesFolder.config;
      folderConfig.defaultView =
          SettingsFolderViewType.fromFolderViewType(newViewType);
      folderConfig.save();
    }
  }

  List<Widget> _buildNoteActions() {
    final repo = context.watch<GitJournalRepo>();

    // SHU-22 app bar: Search + single Sort&View menu (repo switcher is title).
    final sortAndView = PopupMenuButton<String>(
      key: const ValueKey("PopupMenu"),
      tooltip: 'Sort & view',
      icon: const Icon(Icons.tune),
      onSelected: (value) {
        switch (value) {
          case 'sort':
            _sortButtonPressed();
            break;
          case 'layout':
            _folderViewChooserSelected();
            break;
          case 'headers':
            _configureViewButtonPressed();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey("SortingOptions"),
          value: 'sort',
          child: Text(context.loc.widgetsFolderViewSortingOptions),
        ),
        PopupMenuItem(
          key: const ValueKey("FolderViewSelector"),
          value: 'layout',
          child: Text(context.loc.widgetsFolderViewViewsSelect),
        ),
        if (_viewType == FolderViewType.Standard)
          PopupMenuItem(
            key: const ValueKey("ViewOptions"),
            value: 'headers',
            child: Text(context.loc.widgetsFolderViewViewOptions),
          ),
      ],
    );

    return <Widget>[
      IconButton(
        key: const ValueKey("Search"),
        icon: const Icon(Icons.search),
        tooltip: MaterialLocalizations.of(context).searchFieldLabel,
        onPressed: () {
          logEvent(Event.SearchButtonPressed);
          showSearch(
            context: context,
            delegate: NoteSearchDelegate(
              _sortedNotesFolder!.notes,
              _viewType,
            ),
          );
        },
      ),
      sortAndView,
      if (repo.remoteGitRepoConfigured) SyncButton(),
    ];
  }

  List<Widget> _buildInSelectionNoteActions() {
    var extraActions = PopupMenuButton<NoteSelectedExtraActions>(
      key: const ValueKey("PopupMenu"),
      onSelected: (NoteSelectedExtraActions choice) {
        switch (choice) {
          case NoteSelectedExtraActions.MoveToFolder:
            _moveSelectedNotesToFolder();
            break;
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<NoteSelectedExtraActions>>[
        PopupMenuItem<NoteSelectedExtraActions>(
          value: NoteSelectedExtraActions.MoveToFolder,
          child: Text(context.loc.widgetsFolderViewActionsMoveToFolder),
        ),
      ],
    );

    return <Widget>[
      if (_selectedNotes.length == 1)
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () async {
            await shareNote(_selectedNotes.first);
            _resetSelection();
          },
        ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: _deleteSelectedNotes,
      ),
      extraActions,
    ];
  }

  Future<void> _deleteSelectedNotes() async {
    var settings = context.read<Settings>();
    var shouldDelete = true;
    if (settings.confirmDelete) {
      shouldDelete = (await showDialog(
            context: context,
            builder: (context) => NoteDeleteDialog(num: _selectedNotes.length),
          )) ==
          true;
    }
    if (shouldDelete == true) {
      var repo = context.read<GitJournalRepo>();
      repo.removeNotes(_selectedNotes);
    }

    _resetSelection();
  }

  Future<void> _moveSelectedNotesToFolder() async {
    var destFolder = await showDialog<NotesFolderFS>(
      context: context,
      builder: (context) => FolderSelectionDialog(),
    );
    if (destFolder != null) {
      try {
        var repo = context.read<GitJournalRepo>();
        await repo.moveNotes(_selectedNotes, destFolder);
      } catch (ex) {
        showErrorSnackbar(context, ex);
      }
    }

    _resetSelection();
  }

  void _resetSelection() {
    setState(() {
      _selectedNotes = [];
    });
  }
}

class _SliverHeader extends StatelessWidget {
  final String text;
  const _SliverHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(spacingMd, spacingMd, spacingMd, spacingSm),
        child: Text(text, style: textTheme.titleSmall),
      ),
    );
  }
}

Future<void> syncRepo(BuildContext context) async {
  try {
    var container = context.read<GitJournalRepo>();
    await container.syncNotes();
  } catch (e) {
    showErrorSnackbar(context, e);
  }
}
