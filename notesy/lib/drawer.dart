import 'package:flutter/material.dart';
import 'package:notesy/filter.dart';
import 'package:notesy/note.dart';
import 'package:notesy/styles.dart';
import 'package:notesy/utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'drawer_filter.dart';

/// Navigation drawer for the app.
class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer<NoteFilter>(
        builder: (context, filter, _) => Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _drawerHeader(context),
              if (isNotIOS)
                const SizedBox(height: 25),
              DrawerFilterItem(
                icon: Icons.note,
                title: 'Notes',
                isChecked: filter.noteState == NoteState.unspecified,
                onTap: () {
                  filter.noteState = NoteState.unspecified;
                  Navigator.pop(context);
                },
              ),
//        DrawerFilterItem(
//          icon: AppIcons.notifications,
//          title: 'Reminders',
//        ),
              const Divider(),
              DrawerFilterItem(
                icon: Icons.archive,
                title: 'Archive',
                isChecked: filter.noteState == NoteState.archived,
                onTap: () {
                  filter.noteState = NoteState.archived;
                  Navigator.pop(context);
                },
              ),
              DrawerFilterItem(
                icon: Icons.delete,
                title: 'Trash',
                isChecked: filter.noteState == NoteState.deleted,
                onTap: () {
                  filter.noteState = NoteState.deleted;
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              DrawerFilterItem(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.popAndPushNamed(context, '/settings');
                },
              ),
              DrawerFilterItem(
                icon: Icons.help,
                title: 'About',
                onTap: () => launch('https://github.com/aryaanlambe'),
              ),
            ],
          ),
        ),
      );

  Widget _drawerHeader(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 20, left: 30, right: 30),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: kHintTextColorLight,
                fontSize: 26,
                fontWeight: FontWeights.light,
                letterSpacing: -2.5,
              ),
              children: [
                const TextSpan(
                  text: 'Notesy',
                  style: TextStyle(
                    color: kAccentColorLight,
                    fontWeight: FontWeights.semiBold,
                    // fontStyle: FontStyle.italic,
                  ),
                ),
                // const TextSpan(text: ' Keep'),
              ],
            ),
          ),
        ),
      );
}
