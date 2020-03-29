import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesy/drawer.dart';
import 'package:notesy/filter.dart';
import 'package:notesy/note.dart';
import 'package:notesy/notes_grid.dart';
import 'package:notesy/notes_list.dart';
import 'package:notesy/notes_service.dart';
import 'package:notesy/styles.dart';
import 'package:notesy/user.dart';
import 'package:notesy/utils.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

/// Home screen, displays [Note] grid or list.
class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

/// [State] of [HomeScreen].
class _HomeScreenState extends State<HomeScreen> with CommandHandler {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// `true` to show notes in a GridView, a ListView otherwise.
  bool _gridView = false;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
//      statusBarColor: Colors.white,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => NoteFilter(), // watching the note filter
            ),
            Consumer<NoteFilter>(
              builder: (context, filter, child) => StreamProvider.value(
                value: _createNoteStream(
                    context, filter), // applying the filter to Firestore query
                child: child,
              ),
            ),
          ],
          child: Consumer2<NoteFilter, List<Note>>(
            builder: (context, filter, notes, child) {
              final hasNotes = notes?.isNotEmpty == true;
              final canCreate = filter.noteState.canCreate;
              return Scaffold(
                key: _scaffoldKey,
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints.tightFor(width: 720),
                    child: CustomScrollView(
                      slivers: <Widget>[
                        //_appBar(context, filter, child),
                        if (hasNotes)
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ..._buildNotesView(context, filter, notes),
                        if (hasNotes)
                          SliverToBoxAdapter(
                            child: SizedBox(
                                height:
                                    (canCreate ? kBottomBarSize : 10.0) + 10.0),
                          ),
                      ],
                    ),
                  ),
                ),
                drawer: AppDrawer(),
                floatingActionButton: canCreate ? _fab(context) : null,
                bottomNavigationBar: canCreate ? _bottomActions() : null,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                extendBody: true,
              );
            },
          ),
        ),
      );

  Widget _bottomActions() => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Container(
          height: kBottomBarSize,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Row(
            children: <Widget>[
              _buildAvatar(context),
              const SizedBox(width: 30),
              InkWell(
                child: Icon(_gridView ? Icons.list : Icons.grid_on),
                onTap: () => setState(() {
                  _gridView = !_gridView;
                }),
              ),
              const SizedBox(width: 259),
              GestureDetector(
                child: Icon(
                  Icons.search,
                  size: 25,
                  color: Colors.black,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      );

  Widget _fab(BuildContext context) => FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child: const Icon(Icons.add),
        onPressed: () async {
          final command = await Navigator.pushNamed(context, '/note');
          debugPrint('--- noteEditor result: $command');
          processNoteCommand(_scaffoldKey.currentState, command);
        },
      );

  Widget _buildAvatar(BuildContext context) {
    final url = Provider.of<CurrentUser>(context)?.data?.photoUrl;
    return InkWell(
      child: CircleAvatar(
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? const Icon(Icons.face) : null,
        radius: isNotAndroid ? 19 : 17,
      ),
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }

  /// A grid/list view to display notes
  ///
  /// Notes are divided to `Pinned` and `Others` when there's no filter,
  /// and a blank view will be rendered, if no note found.
  List<Widget> _buildNotesView(
      BuildContext context, NoteFilter filter, List<Note> notes) {
    if (notes?.isNotEmpty != true) {
      return [_buildBlankView(filter.noteState)];
    }

    final asGrid = filter.noteState == NoteState.deleted || _gridView;
    final factory = asGrid ? NotesGrid.create : NotesList.create;
    final showPinned = filter.noteState == NoteState.unspecified;

    if (!showPinned) {
      return [
        factory(notes: notes, onTap: _onNoteTap),
      ];
    }

    final partition = _partitionNotes(notes);
    final hasPinned = partition.item1.isNotEmpty;
    final hasUnpinned = partition.item2.isNotEmpty;

    final _buildLabel = (String label, [double top = 26]) => SliverToBoxAdapter(
          child: Container(
            padding:
                EdgeInsetsDirectional.only(start: 26, bottom: 25, top: top),
            child: Text(
              label,
              style: const TextStyle(
                  color: kHintTextColorLight,
                  fontWeight: FontWeights.medium,
                  fontSize: 12),
            ),
          ),
        );

    return [
      if (hasPinned) _buildLabel('PINNED', 0),
      if (hasPinned) factory(notes: partition.item1, onTap: _onNoteTap),
      if (hasPinned && hasUnpinned) _buildLabel('OTHERS'),
      factory(notes: partition.item2, onTap: _onNoteTap),
    ];
  }

  Widget _buildBlankView(NoteState filteredState) => SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Expanded(flex: 1, child: SizedBox()),
            Icon(
              Icons.note_add,
              size: 120,
              color: kAccentColorLight.shade300,
            ),
            Expanded(
              flex: 2,
              child: Text(
                filteredState.emptyResultMessage,
                style: TextStyle(
                  color: kHintTextColorLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  /// Callback on a single note clicked
  void _onNoteTap(Note note) async {
    final command =
        await Navigator.pushNamed(context, '/note', arguments: {'note': note});
    processNoteCommand(_scaffoldKey.currentState, command);
  }

  /// Create notes query
  Stream<List<Note>> _createNoteStream(
      BuildContext context, NoteFilter filter) {
    final user = Provider.of<CurrentUser>(context)?.data;
    final sinceSignUp = DateTime.now().millisecondsSinceEpoch -
        (user?.metadata?.creationTime?.millisecondsSinceEpoch ?? 0);
    final useIndexes = sinceSignUp >=
        _10_min_millis; // since creating indexes takes time, avoid using composite index until later
    final collection = notesCollection(user?.uid);
    final query = filter.noteState == NoteState.unspecified
        ? collection
            .where('state',
                isLessThan: NoteState.archived
                    .index) // show both normal/pinned notes when no filter specified
            .orderBy('state', descending: true) // pinned notes come first
        : collection.where('state', isEqualTo: filter.noteState.index);

    return (useIndexes ? query.orderBy('createdAt', descending: true) : query)
        .snapshots()
        .handleError((e) => debugPrint('query notes failed: $e'))
        .map((snapshot) => Note.fromQuery(snapshot));
  }

  /// Partition the note list by the pinned state
  Tuple2<List<Note>, List<Note>> _partitionNotes(List<Note> notes) {
    if (notes?.isNotEmpty != true) {
      return Tuple2([], []);
    }

    final indexUnpinned = notes?.indexWhere((n) => !n.pinned);
    return indexUnpinned > -1
        ? Tuple2(notes.sublist(0, indexUnpinned), notes.sublist(indexUnpinned))
        : Tuple2(notes, []);
  }
}

const _10_min_millis = 600000;
