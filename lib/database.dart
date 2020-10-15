
import 'dart:math';

import 'package:path/path.dart';

import 'package:lingen_plan/network.dart';
import 'package:sqflite/sqflite.dart';

final String fileName = 'data.db';



class Keys {
  static final int KEY_LAST_IMPORT = 1;
}

class LocalStorageService {
  final String baseTableName = 'data_TIMESTAMP';

  static LocalStorageService instance;

  Database db;

  bool isOpen = false;

  int id = 0; // unique identifier to qualify whether there was a change in the InheritedWidget which caused it to dispose an old instance
  // in that case a new subscription is necessary

  LocalStorageService() {
    if (instance == null) {
      this.id = Random().nextInt(10000);
      instance = this; // singleton
    }
  }

  Future<void> open() async {
    if (!isOpen) {
      // Open the database and store the reference.
      db = await openDatabase(
        join(await getDatabasesPath(), fileName),
        onCreate: (db, version) async {
          await _createDB(db);
        },
        version: 1,
      );

      // TODO: load up latest table

      this.isOpen = true;
    }
  }

  Future close() async {
    await db.close();
    isOpen = false;
    return;
  }

  _createDB(Database database) async {

  }

  Future<String> createTable(int timestamp) async {
    String tableName = baseTableName.replaceAll('TIMESTAMP', timestamp.toString());
    await db.execute(
        'CREATE TABLE $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ${UniEvent.columnDate} VARCHAR(255), ${UniEvent.columnTime} VARCHAR(255), ${UniEvent.columnDuration} VARCHAR(255), ${UniEvent.columnType} VARCHAR(255), ${UniEvent.columnName} VARCHAR(255), ${UniEvent.columnLecturer} VARCHAR(255), ${UniEvent.columnRoom} VARCHAR(255), ${UniEvent.columnGroup} VARCHAR(255))'
    );
    return tableName;
  }

  // returns all the timestamps of available data sorted with latest first
  Future<List<int>> getAllTables() async {
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT name FROM sqlite_master WHERE type = \'table\' ORDER BY name');

    List<int> timestamps = List<int>();

    for (Map<String, dynamic> entry in result) {
      String name = (entry['name'] as String);

      print('name: ' + name);
      if (name.startsWith('data_')) {
        print('replaced: ' + name.replaceAll('data_', ''));
        timestamps.add(int.parse(name.replaceAll('data_', '')));
      }
    }

    return timestamps;
  }

  Future<bool> hasLocalData() async {
    return (await getAllTables()).length > 0;
  }

  Future<int> getLatestTimestamp() async {
    return (await getAllTables()).first;
  }

  Future<int> getOldestTimestamp() async {
    return (await getAllTables()).last;
  }

  Future<int> getTableCount() async {
    return (await getAllTables()).length;
  }

  Future<List<UniEvent>> getEvents(int timestamp) async {
    String tableName = baseTableName.replaceAll('TIMESTAMP', timestamp.toString());
    List<Map<String, dynamic>> values = await db.query(tableName);

    List<UniEvent> result = List<UniEvent>();

    for (Map<String, dynamic> map in values) {
      result.add(UniEvent.fromMap(map));
    }

    return result;
  }

  Future<void> saveEvents(int timestamp, List<UniEvent> newEvents) async {

    // compare with latest saved data -> if no difference, replace || if different save new data
    if (await hasLocalData()) {
      int latestLocalDataTimestamp = await getLatestTimestamp();
      List<UniEvent> latestLocalData = await getEvents(latestLocalDataTimestamp);

      bool hasChanges = newEvents.length != latestLocalData.length;

      if (!hasChanges) {
        for (int i = 0; i < newEvents.length; i++) {
          if (newEvents[i].simpleCompareTo(latestLocalData[i]) != 0) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        // TODO: log notification about changes
        // maybe delete oldest (>12)
        if (await getTableCount() > 12) { // TODO: make max table limit dynamic
          String toDelete = baseTableName.replaceAll('TIMESTAMP', (await getOldestTimestamp()).toString());
          await db.rawQuery('DROP TABLE $toDelete');
        }
      }
      else {
        // delete current latest table
        String toDelete = baseTableName.replaceAll('TIMESTAMP', latestLocalDataTimestamp.toString());
        await db.rawQuery('DROP TABLE $toDelete');
      }
    }

    // add new table with the latest data
    String tableName = await createTable(timestamp);

    for (UniEvent event in newEvents) {
      await db.insert(tableName, event.toMap());
    }
  }

}
