import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:http/http.dart' as http;

// TODO: make dependent on preference by user
final String baseUrl = 'http://sked.lin.hs-osnabrueck.de/sked/grp/19DWF1-1.html';

// returns the menus for a given mensa week
Future<List<UniEvent>> getEvents() async {

  // network call
  http.Response response = await http.get(baseUrl);

  if (response.statusCode != 200) {
    return null;
  }

  // parse retrieved html
  Document document = parse(response.body, encoding: 'utf-8');

  // fetch fields
  Element table = document.getElementsByTagName('table').first;
  List<Element> rows = table.getElementsByTagName('tr');

  // move fields into usable structure
  List<UniEvent> fetchedEvents = List<UniEvent>();

  String lastDate;

  for (Element row in rows) {
    if (row.attributes.containsKey('id')) {
      List<Element> cols = row.getElementsByTagName('td');
      cols.retainWhere((a) { return a.classes != null && a.classes.contains('z');});

      UniEvent uniEvent = UniEvent();
      int colIndex = 0;
      for (Element col in cols) {
        if (col.attributes.containsKey('class') && col.attributes['class'] == 'z') {

          switch (colIndex) {
            case 0:
                if (col.text != null && col.text.replaceAll(' ', '') != '') {
                  lastDate = col.text;
                }
              uniEvent.date = lastDate;
              break;
            case 1:
              uniEvent.time = col.text.replaceAll(' ', '');
              break;
            case 2:
              uniEvent.time += col.text.replaceAll(' ', '');
              break;
            case 3:
              uniEvent.duration = col.text;
              break;
            case 4:
              uniEvent.type = col.text;
              break;
            case 5:
              uniEvent.name = col.text;
              break;
            case 6:
              uniEvent.lecturer = col.text;
              break;
            case 7:
              uniEvent.room = col.text;
              break;
            case 8:
              uniEvent.group = col.text;
              break;
          }
          //print(col.text + '[$colIndex]');
          colIndex++;
        }
      }
      print(uniEvent.toString());
    }
  }

  return fetchedEvents;
}



class ColumnType {
  final int id;
  final String dataName;
  final String title;

  const ColumnType._internal(this.id, this.dataName, this.title);

  static const DATE = const ColumnType._internal(1, UniEvent.columnDate, 'Datum');
  static const TIME = const ColumnType._internal(2, UniEvent.columnTime, 'Uhrzeit');
  static const DURATION = const ColumnType._internal(3, UniEvent.columnDuration, 'Dauer');
  static const TYPE = const ColumnType._internal(4, UniEvent.columnType, 'Art');
  static const NAME = const ColumnType._internal(5, UniEvent.columnName, 'Veranstaltung');
  static const LECTURER = const ColumnType._internal(6, UniEvent.columnLecturer, 'Dozent');
  static const ROOM = const ColumnType._internal(7, UniEvent.columnRoom, 'Raum');
  static const GROUP = const ColumnType._internal(8, UniEvent.columnGroup, 'Studiengruppe');
}

class UniEvent {

  static const String columnId = 'id';
  static const String columnDate = 'date';
  static const String columnTime = 'time';
  static const String columnDuration = 'duration';
  static const String columnType = 'type';
  static const String columnName = 'name';
  static const String columnLecturer = 'lecturer';
  static const String columnRoom = 'room';
  static const String columnGroup = 'grouCol';

  int id;
  String date; // Datum
  String time; // Uhrzeit
  String duration; // Dauer
  String type; // Art
  String name; // Veranstaltung
  String lecturer; // Dozent
  String room; // Raum
  String group; // Studiengruppe

  UniEvent({this.id, this.date, this.time, this.duration, this.type, this.name, this.lecturer, this.room, this.group});


  @override
  toString() {
    String stringed = '';

    if (date != null)
      stringed += date + ' ';
    if (time != null)
      stringed += time + ' ';
    if (duration != null)
      stringed += duration + ' ';
    if (type != null)
      stringed += type + ' ';
    if (name != null)
      stringed += name + ' ';
    if (lecturer != null)
      stringed += lecturer + ' ';
    if (room != null)
      stringed += room + ' ';
    if (group != null)
      stringed += group + ' ';


    return stringed;
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnTime: time,
      columnDate: date,
      columnDuration: duration,
      columnType: type,
      columnName: name,
      columnLecturer: lecturer,
      columnRoom: room,
      columnGroup: group,
    };
  }

  static UniEvent fromMap(Map<String, dynamic> map) {
    return UniEvent(
      id: map[columnId],
      date: map[columnDate],
      time: map[columnTime],
      duration: map[columnDuration],
      type: map[columnType],
      name: map[columnName],
      lecturer: map[columnLecturer],
      room: map[columnRoom],
      group: map[columnGroup],
    );
  }

  //
  String getTime() {
    return time.toString();
  }
  //
  String getDate() {
    return date.toString();
  }


  int simpleCompareTo(UniEvent uniEvent) {
    int difference = 0;
    if (date != uniEvent.date) {
      difference++;
    }
    if (time != uniEvent.time) {
      difference++;
    }
    if (duration != uniEvent.duration) {
      difference++;
    }
    if (type != uniEvent.type) {
      difference++;
    }
    if (name != uniEvent.name) {
      difference++;
    }
    if (lecturer != uniEvent.lecturer) {
      difference++;
    }
    if (room != uniEvent.room) {
      difference++;
    }
    if (group != uniEvent.group) {
      difference++;
    }
    return difference;
  }

  Difference complexCompareTo(UniEvent uniEvent) {
    Difference difference = Difference();
    if (date != uniEvent.date) {
      difference.dateDifference = true;
    }
    if (time != uniEvent.time) {
      difference.timeDifference = true;
    }
    if (duration != uniEvent.duration) {
      difference.durationDifference = true;
    }
    if (type != uniEvent.type) {
      difference.typeDifference = true;
    }
    if (name != uniEvent.name) {
      difference.nameDifference = true;
    }
    if (lecturer != uniEvent.lecturer) {
      difference.lecturerDifference = true;
    }
    if (room != uniEvent.room) {
      difference.roomDifference = true;
    }
    if (group != uniEvent.group) {
      difference.groupDifference = true;
    }
    return difference;
  }


}

class Difference {
  bool dateDifference = false;
  bool timeDifference = false;
  bool durationDifference = false;
  bool typeDifference = false;
  bool nameDifference = false;
  bool lecturerDifference = false;
  bool roomDifference = false;
  bool groupDifference = false;
}