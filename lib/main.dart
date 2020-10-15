import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingen_plan/database.dart';
import 'package:lingen_plan/network.dart';
import 'package:preferences/dropdown_preference.dart';
import 'package:preferences/preference_page.dart';
import 'package:preferences/preference_service.dart';
import 'package:preferences/preference_title.dart';
import 'package:preferences/preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async{
  await PrefService.init(prefix: 'pref_');
  runApp(MyApp());
}

const List<ColumnType> columnArrangement = [ColumnType.DATE, ColumnType.TIME, ColumnType.NAME, ColumnType.ROOM];

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HS Lingen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PreferencesPage(),
    );
  }
}

// TODO: options to set which columns are displayed and in which order -> Draggable list
// TODO: option to show only upcoming events -> checkbox
// TODO: option to change source data link -> text input
// TODO: option to only show certain events (which are relevant to the user) ->
// TODO:    input specific names of modules (autocomplete / choose from loaded ones) to exclude (safer to not miss others)

// TODO: notifications when deltas are detected -> research required
// TODO: maybe color rows of table -> research

// TODO: create page that only shows events of the current and following day


class QuickOverviewPage extends StatefulWidget {
  @override
  State<QuickOverviewPage> createState() {
    return QuickOverviewPageState();
  }

}

class QuickOverviewPageState extends State<QuickOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Überblick'),
      ),
      body: Center(), // ausstehende Veranstaltungen, Änderungen, 60 (today) : 40 (next day)
    );
  }
}


class PreferencesPage extends StatefulWidget {
  @override
  State<PreferencesPage> createState() {
    return PreferencesPageState();
  }
}

class PreferencesPageState extends State<PreferencesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
      ),
      body: PreferencePage([
        PreferenceTitle('Allgemein'),
        DropdownPreference(
          'Startseite',
          'start_page',
          defaultVal: 'Tagesüberblick',
          values: ['Tabelle', 'Tagesüberblick'],
        ),
        PreferenceTitle('Personalization'),
        CheckboxPreference(
          'Vergangene Veranstaltungen anzeigen',
          'show_past_events',
          defaultVal: false,
        ),
        TextFieldPreference(
          'Daten-Quelle',
          'source_address',
          hintText: 'http://bla.blabla.de',
          defaultVal: 'http://',
        ),
        CheckboxPreference(
          'Tabelle einfärben',
          'color_table'
        ),
        SwitchPreference(
          'Benachrichtigungen',
          'notifications',
          defaultVal: true,
          desc: 'Benachrichtigungen zu Änderungen im Veranstaltungsplan',
        ),
        PreferenceDialogLink(
          'Blacklist',
          dialog: PreferenceDialog(
            [
              TextFieldPreference(
                'AAA',
                'VVV'
              )
            ],
            title: 'ABC',
            submitText: 'Abbrechen',
            cancelText: 'Speichern',
          ),
          desc: 'Auszublendende Veranstaltungen',
        ),
      ]),
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
/*
  // Datum
  // Uhrzeit
  // Dauer
  // Art
  // Veranstaltung
  // Dozent
  // Raum
  // Studiengruppe
 */
class _MyHomePageState extends State<MyHomePage> {

  int timeStamp = 0;
  List<UniEvent> data = List<UniEvent>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar( // TODO: move display of date of data inside body
        title: Text('Semesterplan (Stand ' + timeStamp.toString() + ')'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: FutureBuilder(
            future: updateData(true),
            builder: (a, snapshot)  {
              if (snapshot.hasData) { // show result data

                // Create columns
                List<DataColumn> columns = List<DataColumn>();

                for (ColumnType type in columnArrangement) {
                  columns.add(DataColumn(label: Text(type.title)));
                }

                // Take data
                List<DataRow> rows = List<DataRow>();
                for (UniEvent event in data) {
                  List<DataCell> cells = List<DataCell>();
                  Map<String, dynamic> rowData = event.toMap();
                  for (ColumnType type in columnArrangement) {
                    cells.add(DataCell(Text(rowData[type.dataName] as String)));
                  }
                  rows.add(DataRow(cells: cells));
                }

                return
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 80,
                          columns: columns,
                          rows: rows,
                        )
                    ),
                  );
              }
              else if (snapshot.hasError) { // show fail
                return Center(
                  child: Column(
                    children: <Widget>[
                      Icon(Icons.error),
                      Text('This should not have happened')
                    ],
                  ),
                );
              }
              else { // show loading spinner
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }
        ),
      ),
    );
  }

  updateData(bool download) async {

    await LocalStorageService().open();

    LocalStorageService localStorage = LocalStorageService.instance;

    // TODO: check if network available
    if (download) {
      List<UniEvent> events = await getEvents();
      timeStamp = DateTime.now().millisecondsSinceEpoch;
      await localStorage.saveEvents(timeStamp, events);
    }

    if (await localStorage.hasLocalData()) {
      data = await localStorage.getEvents(await localStorage.getLatestTimestamp());
      return true;
    }
    else {
      data = null;
    }

  }
}
