
import 'dart:convert';
import 'package:quiver/core.dart';
import 'package:cube_control/airfieldManager.dart';


class LogbookEntry {
  String id; // unique generated ID - shall be unique world-wide ;)
  int ts; // take-off ts; used for sorting and comparing

  // tracker-collected values:
  String ognId; // used to identify source of the record
  DateTime takeOff, landing;
  double takeOffLat, takeOffLon, landingLat, landingLon;  // [deg]
  int duration; // [s]
  List<double> acc = List(); // recorded min-max accelerations X,Y,Z (CUBEs with accelerometer only)

  // values looked-up based on location:
  String takeOffLocationCode;
  String landingLocationCode;

  // misc. values:
  String pic;   // name/id of this flight's pic
  bool synced;  // synced online

  LogbookEntry(String ognId, DateTime takeOff, DateTime landing, double takeOffLat, double takeOffLon, double landingLat, double landingLon) {
    this.ognId = ognId;
    this.takeOff = takeOff;
    this.landing = landing;
    this.takeOffLat = takeOffLat;
    this.takeOffLon = takeOffLon;
    this.landingLat = landingLat;
    this.landingLon = landingLon;

    duration = landing.difference(takeOff).inSeconds;
    ts = takeOff.millisecondsSinceEpoch ~/ 1000; // [s]
    id = "$ognId-$ts";

    // find nearest airfield, UL strip or town:
    takeOffLocationCode = AirfieldManager().getNearest(takeOffLat, takeOffLon);
    landingLocationCode = AirfieldManager().getNearest(takeOffLat, takeOffLon);
  }

  @override
  int compareTo(LogbookEntry e2) => ts - e2.ts;

  // @override
  // bool equals(LogbookEntry e2) => ts == e2.ts;

  @override
  bool operator == (other) {
    return ognId == other.ognId && ts == other.ts;
  }

  @override int get hashCode {
    return hash3(id, ognId, ts);  // hashX from the quiver package
  }

  String toJson() {
    Map<String, dynamic> m = Map();
//    m['id'] = id;
//    m['ts'] = ts;
    m['ognId'] = ognId;
    m['takeoff'] = takeOff.toIso8601String();
    m['landing'] = landing.toIso8601String();
    m['takeoffLat'] = takeOffLat;
    m['takeoffLon'] = takeOffLon;
    m['landingLat'] = landingLat;
    m['landingLon'] = landingLon;
    m['duration'] = duration;
    m['acc'] = jsonEncode(acc);

    m['takeoffLocCode'] = takeOffLocationCode;
    m['landingLocCode'] = landingLocationCode;

    return jsonEncode(m);
  }

  factory LogbookEntry.fromJson(String jsonStr) {
    Map<String, dynamic> m = jsonDecode(jsonStr);

    LogbookEntry e = new LogbookEntry(
      m['ognId'],
      DateTime.parse(m['takeoff']),
      DateTime.parse(m['landing']),
      m['takeoffLat'],
      m['takeoffLon'],
      m['landingLat'],
      m['landingLon'],
    );

    if (m.containsKey('acc')) {
      if(m['acc'] is String) {
        var l = jsonDecode(m['acc']);
        e.acc = l.cast<double>();

      }  else {
        e.acc = m['acc'].cast<double>();
      }
    }

    e.takeOffLocationCode = m['takeoffLocCode'];
    e.landingLocationCode = m['landingLocCode'];

    return e;
  }

  String getDurationFormatted() {
    int hours = duration ~/ (60*60);
    int temp = duration - hours*60*60;
    int min = temp ~/ 60;
    temp = temp - min * 60;  // remaining seconds
    if (temp > 30) min += 1;

    //print("$duration | $hours h $min m");

    if (hours > 0)
      return "$hoursᵒ $min'";
    else
      return "$min'";
  }
} // ~