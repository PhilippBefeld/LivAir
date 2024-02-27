import 'package:intl/intl.dart';

class MyLineChartData {

  String convertMsToDateString(int ms,int days){
    String date = "";
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(ms);
    if(days == 1){
      return "${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    if(days == 2){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)}\n${dateTime.hour.toString().padLeft(2,"0")}:${dateTime.minute.toString().padLeft(2,"0")}";
    }
    if(days == 7){
      return "${DateFormat('EEEE').format(dateTime).substring(0,2)}";
    }
    if(days == 30){
      return "${DateFormat('d MMM').format(dateTime)}";
    }
    if(days == 0){
      return "${dateTime.day.toString().padLeft(2,"0")}.${dateTime.month.toString().padLeft(2,"0")}.${dateTime.year.toString().substring(2,4)}";
    }
    return "${dateTime.day}.${dateTime.month}.${dateTime.year}  ${dateTime.hour}:${dateTime.minute}";
  }


}