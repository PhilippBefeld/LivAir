
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/data/device.dart';
import '../components/line_chart_data/line_chart_data.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

class DeviceDetailPage extends StatefulWidget {

  final ThingsboardClient tbClient;
  final Map<String,Device2> device;


  const DeviceDetailPage({super.key, required this.tbClient, required this.device});

  @override
  State<DeviceDetailPage> createState() => DeviceDetailPageState(tbClient, device);
}

class DeviceDetailPageState extends State<DeviceDetailPage>{

  final ThingsboardClient tbClient;

  final Dio dio = Dio();
  final logger = Logger();
  final location = Location();

  final Map<String,Device2> device;



  DeviceDetailPageState(this.tbClient,this.device);

  int screenIndex = 0;

  final displayController = TextEditingController();
  final statusLEDController = TextEditingController();
  var value = 0.0;
  final storage = FlutterSecureStorage();
  String? unit;


  WebSocketChannel? channel;
  List<dynamic> radonHistory = [];
  List<Tuple2<int,int>> radonHistoryTimestamps = [];
  List<int> radonValuesTimeseries = [];

  //chart values
  int selectedNumberOfDays = 1;
  int currentMaxValue = 100;
  int currentAvgValue = 0;
  int stepsIntoPast = 1;

  DetailResponse? detailResponse;
  List<Details> details = [];
  String radonValue = "";
  bool futureFuncRunning = false;
  bool telemetryRunning = false;
  bool firstTry = true;
  int requestMsSinceEpoch = 0;

  //deviceInfoScreen values
  String firmwareVersion = "";
  int calibrationDate = 0;

  //deviceLightsScreen values
  double d_led_fb = 1.0;
  double d_led_tb = 1.0;
  bool d_led_t = false;
  bool d_led_f = false;
  TextEditingController orangeMinValue = TextEditingController();
  TextEditingController redMinValue = TextEditingController();
  int d_unit = 1;

  //exportDataScreen values
  bool customTimeseriesSelected = false;
  DateTime customTimeseriesStart = DateTime.now();
  DateTime customTimeseriesEnd = DateTime.now();

  //renameDeviceScreen value
  TextEditingController renameController = TextEditingController();

  //locationScreen values
  TextEditingController locationController = TextEditingController();
  TextEditingController deviceLocationController = TextEditingController();

  //shareDeviceScreen values
  TextEditingController emailController = TextEditingController();
  List<dynamic> viewerData = [];
  String emailToRemove = "";

  //wifiScreen values
  StreamSubscription<List<ScanResult>>? subscription;
  StreamSubscription<List<int>>? subscriptionToDevice;
  StreamSubscription<dynamic>? btChat;
  Map<String, int> foundAccessPoints = {};
  String selectedWifiAccesspoint = "";
  BluetoothDevice? btDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  TextEditingController wifiPasswordController = TextEditingController();

  //offlineData values
  int radonCurrent = 0;
  int radonWeekly = 0;
  int radonEver = 0;

  //warningScreen values
  TextEditingController thresHoldController = TextEditingController();
  int selectedHours = 0;
  int selectedMinutes = 0;


  Future<dynamic> futureFunc() async{
    if(futureFuncRunning) return;
    futureFuncRunning = true;
    unit = await storage.read(key: 'unit');
    radonValue = AppLocalizations.of(context)!.noRadonValues;
    final token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    try{
      channel = WebSocketChannel.connect(
        Uri.parse('wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[
                {
                  "entityType":"DEVICE",
                  "entityId":id,
                  "scope":"CLIENT_SCOPE",
                  "cmdId":1
                }
                ],
            "tsSubCmds":[],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.sink.add(
        jsonEncode(
          {
            "attrSubCmds":[],
            "tsSubCmds": [
              {
                "entityType":"DEVICE",
                "entityId":id,
                "scope":"LATEST_TELEMETRY",
                "cmdId":1
              }
              ],
            "historyCmds":[],
            "entityDataCmds":[],
            "entityDataUnsubscribeCmds":[],
            "alarmDataCmds":[],
            "alarmDataUnsubscribeCmds":[],
            "entityCountCmds":[],
            "entityCountUnsubscribeCmds":[],
            "alarmCountCmds":[],
            "alarmCountUnsubscribeCmds":[]
          },
        ),
      );
      channel!.stream.listen(
            (data) {
              print(data);
              if(jsonDecode(data)["subscriptionId"] == 1 && firstTry){
                firstTry = false;
                requestMsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
                channel!.sink.add(
                  jsonEncode(
                      {
                        "attrSubCmds": [],
                        "tsSubCmds": [],
                        "historyCmds": [],
                        "entityDataCmds": [
                          {
                            "query": {
                              "entityFilter": {
                                "type": "singleEntity",
                                "singleEntity": {
                                  "id": device.keys.elementAt(0),
                                  "entityType": "DEVICE"
                                }
                              },
                              "pageLink": {
                                "pageSize": 1024,
                                "page": 0,
                                "sortOrder": {
                                  "key": {
                                    "type": "ENTITY_FIELD",
                                    "key": "createdTime"
                                  },
                                  "direction": "DESC"
                                }
                              },
                              "entityFields": [
                                {
                                  "type": "ENTITY_FIELD",
                                  "key": "label"
                                },
                                {
                                  "type": "ENTITY_FIELD",
                                  "key": "name"
                                },
                                {
                                  "type": "ENTITY_FIELD",
                                  "key": "additionalInfo"
                                }
                              ],
                              "latestValues": [
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "location"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "locationId"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "floor"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "deviceAdded"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "serialNumber"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastSync"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastActivityTime"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "availableKeys"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "isOnline"
                                }
                              ]
                            },
                            "cmdId": 2
                          }
                        ],
                        "entityDataUnsubscribeCmds": [],
                        "alarmDataCmds": [],
                        "alarmDataUnsubscribeCmds": [],
                        "entityCountCmds": [],
                        "entityCountUnsubscribeCmds": [],
                        "alarmCountCmds": [],
                        "alarmCountUnsubscribeCmds": []
                      }
                  )
                );
                channel!.sink.add(
                  jsonEncode(
                      {
                        "attrSubCmds": [],
                        "tsSubCmds": [],
                        "historyCmds": [],
                        "entityDataCmds": [
                          {
                            "cmdId": 2,
                            "historyCmd": {
                              "keys": [
                                "score",
                                "radon"
                              ],
                              "startTs": 1694383200000,
                              "endTs": requestMsSinceEpoch,
                              "interval": 1000,
                              "limit": 50000,
                              "agg": "NONE"
                            },
                            "latestCmd": {
                              "keys": [
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "location"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "locationId"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "floor"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "deviceAdded"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "serialNumber"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastSync"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastActivityTime"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "availableKeys"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "isOnline"
                                }
                              ]
                            }
                          }
                        ],
                        "entityDataUnsubscribeCmds": [],
                        "alarmDataCmds": [],
                        "alarmDataUnsubscribeCmds": [],
                        "entityCountCmds": [],
                        "entityCountUnsubscribeCmds": [],
                        "alarmCountCmds": [],
                        "alarmCountUnsubscribeCmds": []
                      }
                  ),
                );
              }
              var telData = jsonDecode(data)["data"];
              try{
                var radonData = telData["radon"];
                if(radonData!=null)radonValue = radonData[0][1];
              }catch(e){
              }
              try{
                var dLedFBdata = telData["d_firmware"];
                if(dLedFBdata!=null)firmwareVersion = dLedFBdata[0][1];
              }catch(e){
              }
              try{
                var dLedFBdata = telData["Sensor_kalibriert"];
                if(dLedFBdata!=null)calibrationDate = dLedFBdata[0][0];
              }catch(e){
              }
              try{
                var dLedFBdata = telData["d_led_fb"];
                if(dLedFBdata!=null)d_led_fb = int.parse(dLedFBdata[0][1]).toDouble();
              }catch(e){
              }
              try{
                var dLedTBdata = telData["d_led_tb"];
                if(dLedTBdata!=null)d_led_tb = int.parse(dLedTBdata[0][1]).toDouble();
              }catch(e){
              }
              try{
                var dRangeMdata = telData["d_range_m"];
                if(dRangeMdata!=null)orangeMinValue.text = dRangeMdata[0][1];
              }catch(e){
              }
              try{
                var dRangeTdata = telData["d_range_t"];
                if(dRangeTdata!=null)redMinValue.text = dRangeTdata[0][1];
              }catch(e){
              }
              try{
                var dLedTData = telData["d_led_t"];
                int displayStatus;
                if(dLedTData!=null){
                  displayStatus = int.parse(dLedTData[0][1]);
                    displayStatus==1 ? d_led_t = true : d_led_t = false;
                }
              }catch(e){
              }
              try{
                var dLedFData = telData["d_led_f"];
                int ledStatus;
                if(dLedFData!=null){
                  ledStatus = int.parse(dLedFData[0][1]);
                  setState(() {
                    ledStatus==1 ? d_led_f = true : d_led_f = false;
                  });
                }
              }catch(e){
              }
              try{
                var dUnitData = telData["d_unit"];
                if(dUnitData!=null) d_unit = dUnitData[0][1];
              }catch(e){
              }
              List<dynamic> updateData = [];
              if(jsonDecode(data)["cmdId"]!=null && jsonDecode(data)["update"]!=null)updateData = jsonDecode(data)["update"];
              if(updateData.isNotEmpty) {
                for (var element in updateData) {
                  try {
                    List<dynamic> radonValues = element["timeseries"]["radon"];
                    if (radonValues.isNotEmpty && radonValues.length > 1) {
                      radonHistory = radonValues;
                      radonHistoryTimestamps = [];
                      for (var element in radonHistory) {
                        Tuple2<int,int> singleTimestamp = Tuple2<int,int> (element['ts'], int.parse(element['value']));
                        radonHistoryTimestamps.add(singleTimestamp);
                      }
                      setState(() {
                        channel!.sink.add({
                          "cmds": [
                            {
                              "entityType": "DEVICE",
                              "entityId": device.keys.elementAt(0),
                              "scope": "CLIENT_SCOPE",
                              "cmdId": 1,
                              "unsubscribe": true
                            }
                          ]
                        });
                        screenIndex = 1;
                      });
                    }
                  } catch (e) {
                    logger.e(e);
                  }
                }
              }
              //logger.d(jsonDecode(data));
            },
        onError: (error) => print(error),
      );
    }catch (e) {
      logger.d(e);
    }
  }


  changeDisplayBrightness(){
    if(telemetryRunning)return;
    telemetryRunning = true;
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      var result = dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_led_fb": d_led_fb.toInt(),
            }
        ),
      );
    }catch(e){
      logger.e(e);
    }
    telemetryRunning = false;
  }

  changeLEDBrightness(){
    if(telemetryRunning)return;
    telemetryRunning = true;
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_led_tb": d_led_tb.toInt(),
            }
        ),
      );
    }catch(e){
      logger.e(e);
    }
    telemetryRunning = false;
  }


  void _updateColors() {
    if(int.parse(orangeMinValue.value.text)>=int.parse(redMinValue.value.text) || int.parse(orangeMinValue.value.text)==1) {
      Fluttertoast.showToast(
          msg: 'Bitte Werte korrigieren.'
      );
      return;
    }
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      var result = dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_range_u": 0,
              "u_range_m": int.parse(orangeMinValue.value.text),
              "u_range_t": int.parse(redMinValue.value.text),
            }
        ),
      );
    }catch(e){
      logger.e(e);
    }
  }
  displayOnOff(bool value) {
    int intValue = 0;
    if(value) intValue = 1;
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      var result = dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_led_f": intValue,
            }
        ),
      );
    }catch(e){
      logger.e(e);
    }
  }

  ledOnOff(bool value) async {
    int intValue = 0;
    if(value) intValue = 1;
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      var result = await dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_led_t": intValue,
            }
        ),
      );
    }catch(e){
      print(e);
    }
  }

  void displayType(int value) {
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      var result = dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_view_switch": value,
            }
        ),
      );
    }catch(e){
      logger.e(e);
    }
  }

  List<FlSpot> getCurrentSpots(){
    int startTimeseries =  selectedNumberOfDays == 0 ? radonHistoryTimestamps.last.item1 : requestMsSinceEpoch - (Duration(days: selectedNumberOfDays).inMilliseconds * stepsIntoPast);
    List<FlSpot> spots = [];
    radonValuesTimeseries = [];
    int sum = 0;
    if(selectedNumberOfDays == 0){
      for (var element in radonHistoryTimestamps) {
        sum+=element.item2;
        radonValuesTimeseries.add(element.item2);
        spots.add(FlSpot(Duration(milliseconds: (element.item1-startTimeseries)).inMinutes.toDouble(),element.item2.toDouble()));
      };
    }else{
      for (var element in radonHistoryTimestamps) {
        if(element.item1 >= startTimeseries && element.item1 <= startTimeseries + Duration(days: selectedNumberOfDays).inMilliseconds){
          sum+=element.item2;
          radonValuesTimeseries.add(element.item2);
          spots.add(FlSpot(Duration(milliseconds: (element.item1-startTimeseries)).inMinutes.toDouble(),element.item2.toDouble()));
        }
      };
    }
    if(radonValuesTimeseries.isEmpty){
      currentAvgValue = 0;
      currentMaxValue = 1;
    }else {
      currentAvgValue = sum~/radonValuesTimeseries.length;
      currentMaxValue = radonValuesTimeseries.reduce(max);
    }
    if(selectedNumberOfDays!=0){
      List<FlSpot> newSpots = [];
      int combinationArea = (Duration(days: selectedNumberOfDays).inMinutes~/24);
      int j = 1;
      int k = 0;
      for(int i = Duration(days: selectedNumberOfDays).inMinutes; i >= 0; i-=combinationArea){
        if(24-k-0.5 < 0)break;
        double avgOfArea = 0.0;
        double sum = 0;
        int spotsInArea = 0;
        if(j <= spots.length){
          while(spots.elementAt(j).x >= i-combinationArea && spots.elementAt(j).x <= i){
            spotsInArea+=1;
            sum += spots.elementAt(j).y;
            if(j+1 >= spots.length) {
              j+=2;
              break;
            }
            j+=1;
          }
        }
        if(spotsInArea > 0){
          avgOfArea = sum/spotsInArea;
          if(24-k-0.5 > 0) newSpots.add(FlSpot(24-k-0.5, avgOfArea));
        }
        k+=1;
      }
      return newSpots;
    }
    return spots;
  }


  deviceDetailScreen(){
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: (){
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              Text(device.values.elementAt(0).label!=null ? device.values.elementAt(0).label!  : device.values.elementAt(0).name, style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400)),
              const SizedBox(width: 10,),
              SizedBox(
                width: 45,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        bottom: BorderSide(color: device.values.elementAt(0).isOnline ? const Color(0xffA5E658)  : Colors.grey,),
                        top: BorderSide(color: device.values.elementAt(0).isOnline ? const Color(0xffA5E658)  : Colors.grey),
                        right: BorderSide(color: device.values.elementAt(0).isOnline ? const Color(0xffA5E658)  : Colors.grey,),
                        left: BorderSide(color: device.values.elementAt(0).isOnline ? const Color(0xffA5E658)  : Colors.grey,),
                      )
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        device.values.elementAt(0).isOnline ? "online" : "offline",
                        style: TextStyle(
                          color: device.values.elementAt(0).isOnline ? const Color(0xffA5E658)  : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
          centerTitle: false,
          actions:  [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () async{
                try {
                  final result = await InternetAddress.lookup('example.com');
                  if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                  }
                } on SocketException catch (_) {
                  Fluttertoast.showToast(
                      msg: "No internet connection"
                  );
                  return;
                }
                setState(() {
                  futureFuncRunning = false;
                  firstTry = true;
                });
              },
            ),
            PopupMenuButton(
                itemBuilder: (context)=>[
                  PopupMenuItem(
                    value: 1,
                    child: Text(AppLocalizations.of(context)!.deviceInfo),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 3;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(AppLocalizations.of(context)!.deviceSettings),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 2;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 5,
                    child: Text(AppLocalizations.of(context)!.exportData),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 5;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 6,
                    child: Text(AppLocalizations.of(context)!.shareDevice),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 6;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 8,
                    child: Text(AppLocalizations.of(context)!.warning),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 8;
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 9,
                    child: Text(AppLocalizations.of(context)!.identify),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        identifyDevice();
                      });
                    },
                  ),
                  PopupMenuItem(
                    value: 10,
                    child: Text(AppLocalizations.of(context)!.delete),
                    onTap: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        deleteDevice();
                      });
                    },
                  ),
                ]
            )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.first.item1).inMinutes} ${AppLocalizations.of(context)!.minsAgo}",
                            style: const TextStyle(
                                color: Color(0xff78909C),
                                fontSize: 14,
                                fontWeight: FontWeight.w400
                            ),
                          ),
                          Text("${radonHistoryTimestamps.first.item2} ",
                            style: TextStyle(
                              color: radonHistoryTimestamps.first.item2 > 50 ? radonHistoryTimestamps.first.item2 > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                              fontSize: 32,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          Text(unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ø ${AppLocalizations.of(context)!.avgLast} $selectedNumberOfDays ${AppLocalizations.of(context)!.days}",
                            style: const TextStyle(
                                color: Color(0xff78909C),
                                fontSize: 14,
                                fontWeight: FontWeight.w400
                            ),
                          ),
                          Text("$currentAvgValue ",
                            style: TextStyle(
                                color: currentAvgValue > 50 ? currentAvgValue > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                                fontSize: 32,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                          Text(unit == "Bq/m³" ? "Bq/m³": "pCi/L", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Max. ${AppLocalizations.of(context)!.avgLast} $selectedNumberOfDays ${AppLocalizations.of(context)!.days}",
                            style: const TextStyle(
                                color: Color(0xff78909C),
                                fontSize: 14,
                                fontWeight: FontWeight.w400
                            ),
                          ),
                          Text("$currentMaxValue ",
                            style: TextStyle(
                              color: currentMaxValue > 50 ? currentMaxValue > 300 ? const Color(0xfffd4c56) : const Color(0xfffdca03) : const Color(0xff0ace84),
                              fontSize: 32,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          Text(unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 35,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    children: [
                      Container(
                        height: 20,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                selectedNumberOfDays = 1;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 1 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.last24h,style: TextStyle(
                                color: selectedNumberOfDays == 1 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                selectedNumberOfDays = 2;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 2 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.last48h,style: TextStyle(
                                color: selectedNumberOfDays == 2 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: OutlinedButton(
                            onPressed: ()=>{
                              setState((){
                                selectedNumberOfDays = 7;
                              })
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 7 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.last7d,style: TextStyle(
                                color: selectedNumberOfDays ==7 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: OutlinedButton(
                            onPressed: ()=>{
                              setState((){
                                selectedNumberOfDays = 30;
                              })
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 30 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child:  Text(AppLocalizations.of(context)!.last30d,style: TextStyle(
                                color: selectedNumberOfDays == 30 ? Colors.white : const Color(0xff0099F0)
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                          child: OutlinedButton(
                            onPressed: ()=>{
                              setState((){
                                selectedNumberOfDays = 0;
                              })
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: BorderSide(width: 2,color: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : const Color(0xff4f99F0)),
                                foregroundColor: Colors.black,
                                backgroundColor: selectedNumberOfDays == 0 ? const Color(0xff0099F0) : Colors.white,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.completeHistory,
                              style: TextStyle(
                                  color: selectedNumberOfDays == 0 ? Colors.white : const Color(0xff0099F0)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onPanEnd: (details) {
                    // Swiping in right direction.
                    if (details.velocity.pixelsPerSecond.dx > 0) {
                      setState(() {
                        stepsIntoPast += 1;
                      });
                    }

                    // Swiping in left direction.
                    if (details.velocity.pixelsPerSecond.dx < 0) {
                      if(stepsIntoPast>1){
                        setState(() {
                          stepsIntoPast -= 1;
                        });
                      }
                    }
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: AspectRatio(
                          aspectRatio:0.8,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                            child: LineChart(
                              LineChartData(
                                  maxX: selectedNumberOfDays == 0 ? (Duration(milliseconds: requestMsSinceEpoch - radonHistoryTimestamps.last.item1).inMinutes).toDouble() : 24,
                                  maxY: (currentMaxValue/100.0).ceil()*100.0,
                                  gridData: FlGridData(
                                      show: true,
                                      getDrawingVerticalLine: (value){
                                        return const FlLine(
                                            color: Color(0x00eceff1),
                                            strokeWidth: 1
                                        );
                                      }
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: getCurrentSpots(),
                                      isCurved: true,
                                      curveSmoothness: 0.1,
                                      preventCurveOverShooting: true,
                                      dotData: const FlDotData(
                                          show: false
                                      ),
                                      /*gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: currentMaxValue>300 ? [
                                            Colors.green,
                                            Colors.green,
                                            Colors.orange,
                                            Colors.orange,
                                            Colors.red,
                                            Colors.red,
                                          ] : currentMaxValue>50 ?[
                                            Colors.green,
                                            Colors.green,
                                            Colors.orange,
                                            Colors.orange,

                                          ] : [
                                            Colors.green,
                                            Colors.green,

                                          ],
                                          stops: currentMaxValue>300 ?[0, 50<currentMaxValue ? 45.0/currentMaxValue : 1.0, 50<currentMaxValue ? 55.0/currentMaxValue : 1.0, 300<currentMaxValue ? 295/currentMaxValue : 1.0, 300<currentMaxValue ? 305/currentMaxValue : 3.00,1.0]
                                              : currentMaxValue>50 ?[0, 50<currentMaxValue ? 45.0/currentMaxValue : 1.0, 50<currentMaxValue ? 55.0/currentMaxValue : 1.0, 300<currentMaxValue ? 295/currentMaxValue : 1.0]
                                              :[0, 50<currentMaxValue ? 45.0/currentMaxValue : 1.0]
                                      ),*/
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    getTouchedSpotIndicator:
                                        (LineChartBarData barData, List<int> spotIndexes) {
                                      return spotIndexes.map((index) {
                                        return TouchedSpotIndicatorData(
                                          const FlLine(
                                            strokeWidth: 0,
                                            color: Colors.pink,
                                          ),
                                          FlDotData(
                                            show: true,
                                            getDotPainter: (spot, percent, barData, index) =>
                                                FlDotCirclePainter(
                                                  radius: 8,
                                                  color: spot.y > 50 ? spot.y > 300 ? Colors.red : Colors.orange : Colors.green,
                                                  strokeWidth: 2,
                                                  strokeColor: Colors.black,
                                                ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                    touchTooltipData: LineTouchTooltipData(
                                      maxContentWidth: 100,
                                      tooltipBgColor: Colors.white,
                                      tooltipBorder: const BorderSide(color: Colors.black),
                                      getTooltipItems: (touchedSpots) {
                                        return touchedWidgets(touchedSpots);
                                      },
                                    ),
                                    handleBuiltInTouches: true
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) =>
                                            bottomTitleWidgets(value, meta),
                                        reservedSize: 56,
                                        interval: selectedNumberOfDays == 0 ? (Duration(milliseconds: requestMsSinceEpoch - radonHistoryTimestamps.last.item1).inMinutes).toDouble()/4 : 6,
                                      ),
                                      drawBelowEverything: true,
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50
                                      ),
                                    )
                                  ),
                                  borderData: FlBorderData(
                                      show: false
                                  ),
                                  extraLinesData: ExtraLinesData(
                                      horizontalLines: [
                                        HorizontalLine(
                                            y: currentAvgValue.toDouble(),
                                            dashArray: [20,5]
                                        )
                                      ]
                                  )
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
            ),
          ),
        )
    );
    try{

    }
    catch(e){
      logger.e(e);
    }
  }


  bottomTitleWidgets(double value, TitleMeta meta){
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w400,

    );
    if(selectedNumberOfDays == 0){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds, selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 1){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 2){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*2)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 7){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*7)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    if(selectedNumberOfDays == 30){
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((Duration(days: selectedNumberOfDays).inMilliseconds)-(value*30)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
      );
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(MyLineChartData().convertMsToDateString(requestMsSinceEpoch-(selectedNumberOfDays == 0 ? Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds : (Duration(days: selectedNumberOfDays).inMilliseconds)-(value)*3600000).toInt(), selectedNumberOfDays) , style: style, textAlign:  TextAlign.center,),
    );
  }

  List<LineTooltipItem?> touchedWidgets(List<LineBarSpot> touchedSpots){
    List<LineTooltipItem?> list =  touchedSpots.map((LineBarSpot touchedSpot) {
      final textStyle = TextStyle(
        color: touchedSpot.y > 50 ? touchedSpot.y > 300 ? Colors.red : Colors.orange : Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
      if(selectedNumberOfDays == 0){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds , selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 1){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((24-touchedSpot.x)*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 2){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((24-touchedSpot.x)*2*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 7){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((24-touchedSpot.x)*7*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      if(selectedNumberOfDays == 30){
        return LineTooltipItem(
          '${MyLineChartData().convertMsToDateString((requestMsSinceEpoch-((24-touchedSpot.x)*30*3600000)).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
          textStyle,
        );
      }
      return LineTooltipItem(
        '${MyLineChartData().convertMsToDateString(requestMsSinceEpoch-((selectedNumberOfDays == 0 ? Duration(milliseconds: requestMsSinceEpoch-radonHistoryTimestamps.last.item1).inMilliseconds : Duration(days: selectedNumberOfDays).inMilliseconds) -touchedSpot.x*3600000).toInt(), selectedNumberOfDays)}, ${touchedSpot.y.toStringAsFixed(2)} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}',
        textStyle,
      );
    }).toList();
    return list;
  }

  deviceSettingsScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceSettingsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 20;
              });
            },
            child: Container(
              height: 50.0,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/lights.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.deviceLights,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                connectWithBluetooth();
              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/wifi.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.wifi,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 24;
              });
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/location.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.location,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              readOfflineData();
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const Icon(Icons.bluetooth,color: Colors.black54,),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.localDevice,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),

                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                screenIndex = 1;
              });
              renameDeviceDialog();
            },
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16,),
                      const ImageIcon(AssetImage('lib/images/rename.png')),
                      const SizedBox(width: 14,),
                      Text(AppLocalizations.of(context)!.renameDevice,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  deviceLightsScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceLightsT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.indicatorLights,
                  style: const TextStyle(fontSize: 12),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  d_led_t ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off,
                  style: const TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Switch(
                        value: d_led_t,
                        activeColor: const Color(0xff0099F0),
                        activeTrackColor: const Color(0xffCCEBFC),
                        inactiveTrackColor: Colors.grey,
                        inactiveThumbColor: Colors.white30,
                        onChanged: (value) async{
                          d_led_t = value;
                          await ledOnOff(value);
                          setState(() {
                          });
                        },
                      ),
                      const SizedBox(width: 10,)
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.brightness,
                  style: const TextStyle(
                      fontSize: 12
                  ),
                )
              ],
            ),
            Slider(
              label: d_led_tb.round().toString(),
              activeColor: const Color(0xff0099F0),
              thumbColor: Colors.white,
              inactiveColor: Colors.black12,
              divisions: 16,
              min: 0.0,
              max: 255.0,
              value: d_led_tb,
              onChangeEnd: (value){
                setState(() {
                  d_led_tb = value.round().toDouble();
                });
                changeLEDBrightness();
              },
              onChanged: (value){
              },
            ),
            const SizedBox(height: 20,),
            Row(
              children: [
                Text(AppLocalizations.of(context)!.display, style: const TextStyle(fontSize: 12),)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  d_led_f ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off,
                  style: const TextStyle(
                      fontSize: 16
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Switch(
                        value: d_led_f,
                        activeColor: const Color(0xff0099F0),
                        activeTrackColor: const Color(0xffCCEBFC),
                        inactiveTrackColor: Colors.grey,
                        inactiveThumbColor: Colors.white30,
                        onChanged: (value) async{
                          d_led_f = value;
                          await displayOnOff(value);
                          setState(() {

                          });
                        },
                      ),
                      const SizedBox(width: 10,)
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.brightness,style: const TextStyle(fontSize: 12),)
              ],
            ),
            Slider(
              label: d_led_fb.round().toString(),
              activeColor: const Color(0xff0099F0),
              thumbColor: Colors.white,
              inactiveColor: Colors.black12,
              divisions: 15,
              min: 0.0,
              max: 15.0,
              value: d_led_fb,
              onChangeEnd: (value){
                setState(() {
                  d_led_fb = value.round().toDouble();
                });
                changeDisplayBrightness();
              },
              onChanged: (value){
              },
            ),
            const SizedBox(height: 30),
            Text(AppLocalizations.of(context)!.displayType,style: const TextStyle(fontSize: 12),),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        displayType(0);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: d_unit == 0 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.radon, style: TextStyle(color: d_unit == 0 ?  const Color(0xff0099F0) : Colors.white),),
                        ],
                      )
                  ),
                ),
                const SizedBox(width: 10,),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        displayType(1);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: d_unit == 1 ?  Colors.white : const Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.time, style: TextStyle(color: d_unit == 1 ?  const Color(0xff0099F0) : Colors.white),),
                        ],
                      )
                  ),
                ),
                SizedBox(width: 10,),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        displayType(2);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: d_unit == 1 ?  Colors.white : Color(0xff0099F0),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.changing, style: TextStyle(color: d_unit == 1 ?  Color(0xff0099F0) : Colors.white),),
                        ],
                      )
                  ),
                ),
              ],
            ),


            /*Row( //grenzwertfarbupdate
              children: [
                const SizedBox(width: 30),
                Text("Messwertgrenze orangene LEDs"),
                const SizedBox(width: 10),
                Flexible(
                  child: TextField(
                    controller: orangeMinValue,
                    obscureText: false,
                    onChanged: (value){
                    },
                    onEditingComplete: (){
                      _updateColors();
                    },
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const SizedBox(width: 30),
                const Text("Messwertgrenze rote LEDs"),
                const SizedBox(width: 41),
                Flexible(
                  child: TextField(
                    controller: redMinValue,
                    obscureText: false,
                    onChanged: (value){
                    },
                    onEditingComplete: (){
                      _updateColors();
                    },
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }

  deviceWifiSelectScreen() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice?.cancel();
                  btChat!.cancel();
                  btDevice!.disconnect(timeout: 1);
                }catch(e){
                  print(e);
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10,),
          Row(
            children: [
              const SizedBox(width: 16,),
              Text(AppLocalizations.of(context)!.availableNetworks)
            ],
          ),
          const SizedBox(height: 2,),
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index){
                  return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          screenIndex = 22;
                          selectedWifiAccesspoint = foundAccessPoints.keys.elementAt(index);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          minimumSize: const Size(60,50)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(foundAccessPoints.keys.elementAt(index), style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400),),
                        ],
                      )
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 0,),
                itemCount: foundAccessPoints.length
            ),
          )
        ],
      ),
    );
  }

  deviceWifiPasswordScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                try{
                  subscriptionToDevice?.cancel();
                  btChat!.cancel();
                  btDevice!.disconnect(timeout: 1);
                }catch(e){
                }
                setState(() {
                  screenIndex = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            Text(AppLocalizations.of(context)!.pleaseEnterWifiPassword),
            Text(selectedWifiAccesspoint, style: const TextStyle(fontWeight: FontWeight.bold),),
            const SizedBox(height: 36,),
            Text(AppLocalizations.of(context)!.password),
            const SizedBox(height: 36,),
            TextField(
              controller: wifiPasswordController,
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 36,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        writeCharacteristic!.write(utf8.encode("CONNECT:${foundAccessPoints[selectedWifiAccesspoint]},|${wifiPasswordController.text}"));
                        print("CONNECT:${foundAccessPoints[selectedWifiAccesspoint]},|${wifiPasswordController.text}");
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: const Color(0xff0099f0),
                          backgroundColor: const Color(0xff0099f0),
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.connect,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  connectWithBluetooth() async{
    int foundAccesspointCount = 0;
    int counter = 0;
    foundAccessPoints = {};

    showDialog(context: context, builder: (context){
      return WillPopScope(
        onWillPop: () async{ return false; },
        child: Scaffold(
          body: Center(
              child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.searchingDevAndWifi1),
                  Text(AppLocalizations.of(context)!.searchingDevAndWifi2),
                  const SizedBox(height: 36,),
                  const CircularProgressIndicator(color: Colors.black,),
                ],
              )
          )
        ),
      );
    });
    await FlutterBluePlus.turnOn();
    var locationEnabled = await location.serviceEnabled();
    if(!locationEnabled){
      var locationEnabled2 = await location.requestService();
      if(!locationEnabled2){
      }
    }
    var permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
      }
    }
    FlutterBluePlus.stopScan();
    bool deviceFound = false;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!deviceFound) {
          List<int> bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
          String bluetoothDeviceName = "";
          if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
          if(bluetoothDeviceName==device.values.first.name) {
            deviceFound = true;
            btDevice = r.device;
            await r.device.connect();
            await r.device.requestMtu(100);
            List<BluetoothService> services = await r.device.discoverServices();
            for (var service in services){
              for(var characteristic in service.characteristics){
                if(characteristic.properties.notify){
                  await characteristic.setNotifyValue(true);
                  readCharacteristic = characteristic;
                  subscriptionToDevice = characteristic.lastValueStream.listen((data) async{
                    String message = utf8.decode(data).trim();
                    print(utf8.decode(data));
                    if(message == ""){
                      await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                    }
                    if(message == 'LOGIN OK'){
                      await writeCharacteristic!.write(utf8.encode('SCAN'));
                    }
                    if(message.length >=7){
                      if(message.substring(0,6) == 'Found:'){
                        foundAccesspointCount = int.parse(message.substring(6,message.length));
                      }
                    }
                    if(message.length>= 4 && message.contains(",|")){
                      foundAccessPoints.addEntries([MapEntry(message.substring(message.indexOf("|")+1,message.indexOf(",",message.indexOf("|")+1)),int.parse(message.substring(0,message.indexOf(","))))]);
                      counter++;
                      if(counter==foundAccesspointCount){
                        Navigator.pop(context);
                        setState(() {
                          screenIndex = 21;
                        });
                      }
                    }
                    if(message == 'Connect Success'){
                      btDevice!.disconnect(timeout: 1);
                      subscriptionToDevice?.cancel();
                      setState(() {
                        screenIndex = 1;
                      });
                    }
                  });
                }
                if(characteristic.properties.write){
                  writeCharacteristic = characteristic;
                  try{
                    await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
                  }catch(e){
                    print(e);
                  }
                }
              }
            }
          }
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
    await Future<void>.delayed( const Duration(seconds: 2));
    if(!deviceFound){
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "No devices found"
      );
    }
  }

  readOfflineData() async{
    foundAccessPoints = {};

    showDialog(context: context, builder: (context){
      return Scaffold(
          body: Center(
              child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.searchingDevice),
                  const SizedBox(height: 36,),
                  const CircularProgressIndicator(color: Colors.black,),
                ],
              )
          )
      );
    });
    await FlutterBluePlus.turnOn();
    var locationEnabled = await location.serviceEnabled();
    if(!locationEnabled){
      var locationEnabled2 = await location.requestService();
      if(!locationEnabled2){
      }
    }
    var permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
      }
    }
    FlutterBluePlus.stopScan();
    bool deviceFound = false;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (!deviceFound) {
          List<int> bluetoothAdvertisementData = r.advertisementData.manufacturerData.values.first;
          String bluetoothDeviceName = "";
          if(r.advertisementData.manufacturerData.keys.first == 3503) bluetoothDeviceName += utf8.decode(bluetoothAdvertisementData.sublist(15,23));
          if(bluetoothDeviceName == device.values.first.name){
            radonCurrent = bluetoothAdvertisementData.elementAt(1);
            radonWeekly = bluetoothAdvertisementData.elementAt(5);
            radonEver = bluetoothAdvertisementData.elementAt(9);
            FlutterBluePlus.stopScan();
            subscription!.cancel();
            setState(() {
              Navigator.pop(context);
              screenIndex = 23;
            });
          }
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
    await Future<void>.delayed( const Duration(seconds: 2));
    if(!deviceFound){
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "The device wasn't found"
      );
    }
  }

  offlineDataScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 2;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.noWifiNeeded),
            const SizedBox(height: 30,),
            Text(AppLocalizations.of(context)!.live,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xff78909c)),),
            const SizedBox(height: 4,),
            Text("$radonCurrent ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}",style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.weekly,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xff78909c)),),
            const SizedBox(height: 4,),
            Text("$radonWeekly ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}",style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.sinceConnected,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xff78909c)),),
            const SizedBox(height: 4,),
            Text("$radonEver ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"}",style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),),
            ]
        ),
      ),
    );
  }

  changeLocationScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 2;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.deviceLocation),
                  const SizedBox(height: 5,),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      hintText: device.values.first.location,
                      hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                    ),
                  ),
                  GooglePlaceAutoCompleteTextField(
                    textEditingController: deviceLocationController,
                    googleAPIKey: "AIzaSyDbedbD3jc34d-eYRUw1PC-vT4sPFeBdMQ",
                    inputDecoration: InputDecoration(),
                    debounceTime: 800, // default 600 ms,
                    //countries: ["in","fr"],// optional by default null is set
                    isLatLngRequired:true,// if you required coordinates from place detail
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      // this method will return latlng with place detail
                      print("placeDetails" + prediction.lng.toString());
                    }, // this callback is called when isLatLngRequired is true
                    itemClick: (Prediction prediction) {
                      deviceLocationController.text = prediction.description!;
                      deviceLocationController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description!.length));
                    },
                    // if we want to make custom list item builder
                    itemBuilder: (context, index, Prediction prediction) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(
                              width: 7,
                            ),
                            Expanded(child: Text("${prediction.description??""}"))
                          ],
                        ),
                      );
                    },
                    // if you want to add seperator between list items
                    seperatedBuilder: Divider(),
                    // want to show close icon
                    isCrossBtnShown: true,
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        renameDevice();
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.rename,style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ]
        ),
      ),
    );
  }

  changeLocation() async{
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var result;
    try{
    }catch(e){
      setState(() {
        Navigator.pop(context);
      });
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedNewLocationM
      );
    }
    Navigator.pop(context);
    setState(() {
      screenIndex = 1;
    });
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successNewLocationM
    );
  }


  dataExportScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.exportDataT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10,),
                Text(
                  AppLocalizations.of(context)!.exportDialog, style: const TextStyle(fontSize: 16),),
                const SizedBox(height: 30,),
                Text(AppLocalizations.of(context)!.timeFrame, style: const TextStyle(fontSize: 12),),
                const SizedBox(height: 8,),
                SizedBox(
                  height: 35,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                customTimeseriesSelected = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                foregroundColor: Colors.black,
                                backgroundColor: customTimeseriesSelected ? Colors.white : const Color(0xff0099f0),
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.allData,style: TextStyle(
                                color: customTimeseriesSelected ? const Color(0xff0099f0) : Colors.white
                            ),),
                          ),
                        ),
                      ),
                      Container(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                          child: OutlinedButton(
                            onPressed: (){
                              setState((){
                                customTimeseriesSelected = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                ),
                                side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                foregroundColor: Colors.black,
                                backgroundColor: customTimeseriesSelected ? const Color(0xff0099f0) : Colors.white ,
                                minimumSize: const Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.custom,style: TextStyle(
                                color: customTimeseriesSelected ? Colors.white : const Color(0xff0099f0)
                            ),),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20,),
                Text(
                  AppLocalizations.of(context)!.timePeriod,
                  style: const TextStyle(
                      fontSize: 12
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(Duration(milliseconds: radonHistoryTimestamps != [] ? radonHistoryTimestamps.first.item1 : 0)),
                            lastDate: DateTime.now()
                        );

                        if(newDate == null) return;

                        setState(() => customTimeseriesStart = newDate);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 1,color: Color(0xffECEFF1))),
                      child: Text("${AppLocalizations.of(context)!.from} ${DateFormat('yyyy-MM-dd').format(customTimeseriesStart)}"),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(Duration(milliseconds: radonHistoryTimestamps != [] ? radonHistoryTimestamps.first.item1 : 0)),
                            lastDate: DateTime.now()
                        );

                        if(newDate == null) return;
                        if(newDate.year == DateTime.now().year && newDate.month == DateTime.now().month && newDate.day == DateTime.now().day) {
                          setState(() => customTimeseriesEnd = DateTime.now());
                          return;
                        }
                        setState(() => customTimeseriesEnd = newDate);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(width: 1,color: Color(0xffECEFF1))),
                      child: Text("${AppLocalizations.of(context)!.until} ${DateFormat('yyyy-MM-dd').format(customTimeseriesEnd)}"),
                    ),
                  ],
                )
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async{
                          try {
                            final result = await InternetAddress.lookup('example.com');
                            if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                            }
                          } on SocketException catch (_) {
                            Fluttertoast.showToast(
                                msg: "No internet connection"
                            );
                            return;
                          }
                          exportData();
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: Size(100, 50)),
                        child: Text(AppLocalizations.of(context)!.export,style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saveData,
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                        child: Text(AppLocalizations.of(context)!.saveToDownloads,style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  exportData() async{
    final path = await _localPath;
    File file = File('$path/Device_details.txt');
    file.writeAsString("\ndevice name   timestamp   radon");
    for (var element in radonHistoryTimestamps) {
      if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesStart) >= 0){
        if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesEnd) <= 0){
          await file.writeAsString("\n${device.values.first.name}   ${DateFormat('yyyy-MM-dd hh:mm').format(DateTime.fromMillisecondsSinceEpoch(element.item1))}   ${element.item2}",mode: FileMode.append);
        }
      }
    }

    final result = await Share.shareXFiles([XFile('$path/Device_details.txt')], text: "Shared with LivAir App");
    if(result.status == ShareResultStatus.success){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.successExportShareM
      );
    }
  }

  saveData () async{
    File file = File('/storage/emulated/0/Download/Device_details.txt');
    await file.writeAsString("\ndevice name   timestamp   radon");
    for (var element in radonHistoryTimestamps) {
      if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesStart) >= 0){
        if(DateTime.fromMillisecondsSinceEpoch(element.item1).compareTo(customTimeseriesEnd) <= 0){
          await file.writeAsString("\n${device.values.first.name}   ${DateFormat('yyyy-MM-dd hh:mm').format(DateTime.fromMillisecondsSinceEpoch(element.item1))}   ${element.item2}",mode: FileMode.append);
        }
      }
    }
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successSavedM
    );
  }

  renameDevice () async{
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var result;
    try{
      result = await dio.post('https://dashboard.livair.io/api/livAir/renameDevice/${device.keys.first}/${renameController.text}',);
    }catch(e){
      setState(() {
        Navigator.pop(context);
      });
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.failedRenameM
      );
    }
    Navigator.pop(context);
    setState(() {
      device.values.first.label = renameController.text;
      screenIndex = 1;
    });
    Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.successRenameM
    );
  }

  renameDeviceDialog () async{
    renameController.text = device.values.first.label!;
    await Future.delayed(const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.rename, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            keyboardType: TextInputType.number,
            controller: renameController,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
              ),
              fillColor: Colors.white,
              filled: true,

              hintText: "${device.values.first.label}",
              hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
            ),
          ),
          const SizedBox(height: 30,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async{
                    try {
                      final result = await InternetAddress.lookup('example.com');
                      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                      }
                    } on SocketException catch (_) {
                      Fluttertoast.showToast(
                          msg: "No internet connection"
                      );
                      return;
                    }
                    renameDevice();
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.rename,style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
  }
  
  shareDeviceScreen(){
    return FutureBuilder(
      future: getViewers(), 
        builder: (context,snapshot){
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            backgroundColor: Colors.white,
            titleSpacing: 0,
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            title: Text(AppLocalizations.of(context)!.manageUsersT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
            actions: [
              IconButton(
                  onPressed: () async{
                    try {
                      final result = await InternetAddress.lookup('example.com');
                      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                      }
                    } on SocketException catch (_) {
                      Fluttertoast.showToast(
                          msg: "No internet connection"
                      );
                      return;
                    }
                    setState(() {
                      screenIndex = 7;
                    });
                  },
                  color: const Color(0xff0099f0),
                  icon: const Icon(MaterialSymbols.add)
              ),
            ],
          ),
          body: viewerData.isEmpty ?
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ImageIcon(AssetImage('lib/images/users.png'),size: 55,),
                  const SizedBox(height: 15,),
                  Text(AppLocalizations.of(context)!.noUsersYet,style: const TextStyle(fontSize: 20),),
                  const SizedBox(height: 5,),
                  Text(AppLocalizations.of(context)!.addUserDialog,style: const TextStyle(fontSize: 16),textAlign: TextAlign.center,),
                  const SizedBox(height: 30,),
                  OutlinedButton(
                    onPressed: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      setState(() {
                        screenIndex = 7;
                      });
                    },
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0)),
                    child: Text(AppLocalizations.of(context)!.addUser,style: const TextStyle(color: Colors.white),),
                  )
                ],
              ),
            ),
          ):
          Column(
            children: [
              Expanded(
                child: ListView.separated(
                    itemBuilder: (BuildContext context, int index){
                      return GestureDetector(
                        onTap: (){

                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            height: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${viewerData.elementAt(index).values.elementAt(0)}",style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                                viewerData.elementAt(index).values.elementAt(1) == true ?
                                SizedBox(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xffA5E658)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(AppLocalizations.of(context)!.active,style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xffA5E658),))
                                    ),
                                  )
                                ) :
                                SizedBox(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(AppLocalizations.of(context)!.pendingInvite,style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                                      ),
                                    )
                                ),
                                IconButton(
                                    onPressed: () async{
                                      try {
                                        final result = await InternetAddress.lookup('example.com');
                                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                                        }
                                      } on SocketException catch (_) {
                                        Fluttertoast.showToast(
                                            msg: "No internet connection"
                                        );
                                        return;
                                      }
                                      emailToRemove = viewerData.elementAt(index).values.elementAt(0);
                                      removeViewerDialog();
                                    },
                                    icon: const ImageIcon(AssetImage('lib/images/TrashbinButton.png'))
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 1),
                    itemCount: viewerData.length,
                ),
              )
            ],
          ),
        );
        },
    );
  }

  addViewerScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 6;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black
                      ),
                      children: <TextSpan>[
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog1),
                        TextSpan(text: "${device.values.first.label}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog2)
                      ]
                  ),
                ),
                const SizedBox(height: 36,),
                Text(AppLocalizations.of(context)!.inviteViewer),
                const SizedBox(height: 36,),
                TextField(
                  textAlign: TextAlign.start,
                  controller: emailController,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: AppLocalizations.of(context)!.email,
                    hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        isValidEmail() == true ? sendShareInvite : null;
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.invite, style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ]
          ),

      ),
    );
  }

  sendShareInvite() async {
    if(!isValidEmail())return;
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var response;
    try{
      response = await dio.post(
          'https://dashboard.livair.io/api/livAir/share',
        data: jsonEncode(
            {
              "deviceIds": [device.keys.elementAt(0)],
              "email": emailController.text
            }
        )
      );
    }on DioError catch (e){
      logger.e(e.message);
    }
    setState(() {
      screenIndex = 6;
    });
  }

  getViewers() async {
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var response;
    try{
      response = await dio. get(
          'https://dashboard.livair.io/api/livAir/viewers/${device.keys.elementAt(0)}',
      );
      viewerData = response.data;
    }catch(e){
      print(e);
    }
  }

  removeViewerDialog(){
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.removeUserFromDevs, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.removeUserDialog,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 30,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async{
                    try {
                      final result = await InternetAddress.lookup('example.com');
                      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                      }
                    } on SocketException catch (_) {
                      Fluttertoast.showToast(
                          msg: "No internet connection"
                      );
                      return;
                    }
                    removeViewer();
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.removeUser,style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: Size(100, 50)),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
  }

  removeViewer() async{
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var response;
    try{
      response = await dio.delete(
        'https://dashboard.livair.io/api/livAir/unshare',
        data: jsonEncode({
          "deviceIds": [device.keys.first],
          "email": emailToRemove
        })
      );
      viewerData = response.data;
    }on DioError catch(e){
      print(e.response);
    }
    emailToRemove = "";
    setState(() {

    });
  }

  showSelectThresholdScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 1;
            });
          },
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.selectThresholdT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.selectThresholdDialog1),
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: thresHoldController,
                  autofocus: true,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                    hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                  ),

                ),
                const SizedBox(height: 10),
                Text("${AppLocalizations.of(context)!.selectThresholdDialog2} ${unit == "Bq/m³" ? "Bq/m³": "pCi/L"},${AppLocalizations.of(context)!.selectThresholdDialog3}"
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: (){
                        setState(() {
                          screenIndex = 81;
                        });
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.selectThreshold,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  showSelectDurationScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 1;
            });
          },
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.selectDurationT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.selectDurationDialog),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimePickerSpinner(
                  time: DateTime.fromMillisecondsSinceEpoch(0),
                  is24HourMode: true,
                  minutesInterval: 10,
                  onTimeChange: (time){
                    setState(() {
                      selectedHours = time.hour;
                      selectedMinutes = time.minute;
                    });
                  },
                ),
                const SizedBox(width: 20,),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () async{
                        try {
                          final result = await InternetAddress.lookup('example.com');
                          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                          }
                        } on SocketException catch (_) {
                          Fluttertoast.showToast(
                              msg: "No internet connection"
                          );
                          return;
                        }
                        setState(() {
                          updateWarning();
                          screenIndex = 1;
                        });
                      } ,
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.createWarning,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  updateWarning() async{
    final token = tbClient.getJwtToken();
    final dio = Dio();

    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    try{
      dio.post(
        "https://dashboard.livair.io/api/livAir/warning",
        data: jsonEncode(
            {
              "deviceId": device.keys.first,
              "radonUpperThreshold": int.parse(thresHoldController.text),
              "radonAlarmDuration": selectedHours*60+selectedMinutes
            }
        ),
      );
    }catch(e){
      print(e);
    }
    selectedMinutes = 0;
    selectedHours = 0;
    thresHoldController.text = "";
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  showDeviceInfoScreen(){
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  screenIndex = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.deviceInfoT,style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.deviceId),
            const SizedBox(height: 10,),
            Text(device.values.first.name, style: const TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.firmwareVersion),
            const SizedBox(height: 10,),
            Text(firmwareVersion, style: const TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20,),
            Text(AppLocalizations.of(context)!.calibrationDate),
            const SizedBox(height: 10,),
            Text(DateTime.fromMillisecondsSinceEpoch(calibrationDate).toIso8601String().split("T").first, style: const TextStyle(fontWeight: FontWeight.w600),),
          ],
        ),
      ),
    );
  }

  identifyDevice() async{
    await Future<void>.delayed( const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.identifying, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.identifyingDialog)
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
    var token = tbClient.getJwtToken();
    String id = device.keys.elementAt(0);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    try{
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_identify": 1,
            }
        ),
      );
      await Future<void>.delayed( const Duration(seconds: 10));
      dio.post('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/$id/SHARED_SCOPE',
        data: jsonEncode(
            {
              "u_identify": 0,
            }
        ),
      );
      Navigator.pop(context);
    }catch(e){
      logger.e(e);
    }
    telemetryRunning = false;
  }

  deleteDevice() async {
    await Future<void>.delayed( const Duration(milliseconds: 100));
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteDev, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.deleteDevDialog),
          const SizedBox(height: 30,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: "No internet connection"
                        );
                        return;
                      }
                      var token = tbClient.getJwtToken();
                      String id = device.keys.elementAt(0);
                      dio.options.headers['content-Type'] = 'application/json';
                      dio.options.headers['Accept'] = "application/json";
                      dio.options.headers['Authorization'] = "Bearer $token";
                      await dio.post("https://dashboard.livair.io/api/livAir/unclaim/$id");
                      await Future<void>.delayed( const Duration(milliseconds: 100));
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50),side: const BorderSide(color: Color(0xff0099f0))),
                    child: Text(AppLocalizations.of(context)!.deleteDev,style: const TextStyle(color: Colors.white),)
                ),
              ),

            ],
          ),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: ()=> setState(() {
                      Navigator.pop(context);
                    }),
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50), side: const BorderSide(color: Color(0xff0099f0))),
                    child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Color(0xff0099f0)),)
                ),
              ),
            ],
          )
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context){
        return alert;
      },
    );
  }

  setPage(int index){
    switch(index) {
      case 0: return const Column();
      case 1: return deviceDetailScreen();
      case 2: return deviceSettingsScreen();
      case 20: return deviceLightsScreen();
      case 21: return deviceWifiSelectScreen();
      case 22: return deviceWifiPasswordScreen();
      case 23: return offlineDataScreen();
      case 24: return changeLocationScreen();
      case 3: return showDeviceInfoScreen();
      case 5: return dataExportScreen();
      case 6: return shareDeviceScreen();
      case 7: return addViewerScreen();
      case 8: return showSelectThresholdScreen();
      case 81: return showSelectDurationScreen();
      default: return;
    }
  }

  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(emailController.text);
  }


  @override
  Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: () async{
          return false;
        },
        child: FutureBuilder(
            future: futureFunc(),
            builder: (context, projectSnap){
              return setPage(screenIndex);
            }
        ),
      );
  }

}

class DetailResponse {
  final Map<String, dynamic> data;

  DetailResponse(this.data);

  DetailResponse.fromJson(List<dynamic> json)
      : data = json[0];
}

class Details {
  final String key;
  final String value;
  final String color;
  final String rating;

  Details({
    required this.key,
    required this.value,
    required this.color,
    required this.rating,
  });


  factory Details.fromJson(Map<String, dynamic> json) => Details(
    key: json["key"].toString(),
    value: json["value"].toString(),
    color: json["color"].toString(),
    rating: json["rating"].toString(),
  );
}

abstract class Observable{

}