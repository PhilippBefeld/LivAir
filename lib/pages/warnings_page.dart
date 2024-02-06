
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/my_device_widget.dart';

class WarningsPage extends StatefulWidget {

  final ThingsboardClient tbClient;

  const WarningsPage({super.key, required this.tbClient});

  @override
  State<WarningsPage> createState() => WarningsPageState(tbClient);
}

class WarningsPageState extends State<WarningsPage>{

  final ThingsboardClient tbClient;
  final Logger logger = Logger();

  final storage = FlutterSecureStorage();
  String? unit;

  WarningsPageState(this.tbClient);
  //page variables
  int index = 0;

  //warnings
  List<dynamic> warnings = [];

  //devices and new warnings variables
  List<String> deviceIds = [];
  List<String> labels = [];
  List<bool> areOnline = [];
  List<String> lastSyncs = [];
  String selectedDevice = "";
  TextEditingController thresholdController = TextEditingController();
  int selectedHours = 0;
  int selectedMinutes = 0;


  getAllWarnings() async {
    warnings = [];
    unit = await storage.read(key: 'unit');
    final token = tbClient.getJwtToken();
    final dio = Dio();

    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    var response;
    try {
      response = await dio.get('https://dashboard.livair.io/api/livAir/warnings');
    }catch(e){
      print(e);
    }
    List<dynamic> data = response.data;
    for (var element in data) {
      warnings.add(element);
    }
    print(response.data);
  }

  Widget showWarningsScreen(){
    if(warnings.isEmpty){
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xffF7F9F9),
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.warningsT, style: TextStyle(color: Colors.black),),
            ],
          ),
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: [
            IconButton(
              onPressed: (){
                setState(() {
                  index = 1;
                });
              },
              icon: Icon(Icons.add,color: const Color(0xff0099f0),),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ImageIcon(AssetImage('lib/images/ListButton_Circle.png'),size: 50,),
              const SizedBox(height: 15,),
              Text(AppLocalizations.of(context)!.noWarningsYet),
              const SizedBox(height: 30,),
              OutlinedButton(
                onPressed: getAllDevices,
                style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0)),
                child: Text(AppLocalizations.of(context)!.addWarning,style: const TextStyle(color: Colors.white),),
              )
            ],
          ),
        ),
      );
    }else{
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xffF7F9F9),
          title: Row(
            children: [
              Text(AppLocalizations.of(context)!.warningsT,style: TextStyle(color: Colors.black),),
            ],
          ),
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          actions: [
            IconButton(
                onPressed: (){
                  setState(() {
                    getAllDevices();
                  });
                },
                icon: Icon(Icons.add,color: const Color(0xff0099f0),),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(height: 1),
                  itemCount: warnings.length,
                  itemBuilder: (BuildContext context, int index){
                    return GestureDetector(
                        onTap: (){

                        },
                        child: Container(
                          height: 114,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${warnings.elementAt(index).values.elementAt(1)}",
                                    style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 16,),
                                  Text("      ${warnings.elementAt(index).values.elementAt(2)} ${warnings.elementAt(index).values.elementAt(4)}",
                                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  Text(Duration(minutes: warnings.elementAt(index).values.elementAt(3)).toString().substring(0,4),
                                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                              IconButton(
                                  onPressed: (){
                                    selectedDevice = warnings.elementAt(index).values.elementAt(0);
                                    deleteWarningDialog();
                                  },
                                  color: Colors.black,
                                  icon: ImageIcon(AssetImage('lib/images/TrashbinButton.png'),)
                              )
                            ],
                          ),
                        )
                    );
                  },
              ),
            )
          ],
        ),
      );
    }
  }

  getAllDevices(){
    deviceIds = [];
    labels = [];
    areOnline = [];
    lastSyncs = [];
    WebSocketChannel? channel;
    final token = tbClient.getJwtToken();
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
            'wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
      channel.sink.add(
          jsonEncode(
              {
                "attrSubCmds": [],
                "tsSubCmds": [],
                "historyCmds": [],
                "entityDataCmds": [
                  {
                    "query": {
                      "entityFilter": {
                        "type": "entitiesByGroupName",
                        "resolveMultiple": true,
                        "groupStateEntity": true,
                        "stateEntityParamName": null,
                        "groupType": "DEVICE",
                        "entityGroupNameFilter": "All"
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
                          "key": "name"
                        },
                        {
                          "type": "ENTITY_FIELD",
                          "key": "label"
                        }
                      ],
                      "latestValues": [
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
                          "key": "isOnline"
                        }
                      ]
                    },
                    "cmdId": 1
                  },

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
      channel.stream.listen((data) {
        print(jsonDecode(data));
        List<dynamic> deviceData = jsonDecode(data)["data"]["data"];
        for(var element in deviceData){
          deviceIds.add(element["entityId"]["id"]);
          labels.add(element["latest"]["ENTITY_FIELD"]["label"]["value"]);
          areOnline.add(bool.parse(element["latest"]["ATTRIBUTE"]["isOnline"]["value"]));
          lastSyncs.add(element["latest"]["ATTRIBUTE"]["lastSync"]["value"]);
        }
        setState(() {
          index = 1;
        });
      });
    }catch(e){

    }
  }
  showSelectThresholdScreen(){
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: const Color(0xffF7F9F9),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  index = 1;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.selectThresholdT,style: TextStyle(color: Colors.black),),
          ],
        ),
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
                  controller: thresholdController,
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
                      onPressed: ()=> setState(() {
                        index = 3;
                      }),
                      style: OutlinedButton.styleFrom(backgroundColor: Color(0xff0099f0),minimumSize: Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.selectDuration,style: TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  showDeviceSelectScreen(){
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(
            color: Colors.black,
          ),
          backgroundColor: const Color(0xffF7F9F9),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: (){
                  setState(() {
                    index = 0;
                  });
                },
              ),
              Text(AppLocalizations.of(context)!.selectDeviceT,style: const TextStyle(color: Colors.black),),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 10,),
                padding: const EdgeInsets.only(bottom: 10),
                itemCount: labels.length,
                itemBuilder: (BuildContext context, int deviceIndex) {
                  return MyDeviceWidget(
                    onTap: (){
                      selectedDevice = deviceIds[deviceIndex];
                      setState(() {
                        index = 2;
                      });
                    },
                    name: labels[deviceIndex],
                    isOnline: areOnline[deviceIndex],
                    radonValue: "-1",
                    unit: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                  );
                },
              ),
            ),],
        ),
      );
  }

  showSelectDurationScreen(){
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        backgroundColor: const Color(0xffF7F9F9),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: (){
                setState(() {
                  index = 2;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.selectDurationT,style: const TextStyle(color: Colors.black),),
          ],
        ),
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
                SizedBox(width: 20,),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: ()=> setState(() {
                        updateWarning();
                        index = 0;
                      }),
                      style: OutlinedButton.styleFrom(backgroundColor: Color(0xff0099f0),minimumSize: Size(100, 50)),
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

    print(selectedDevice);
    try{
      dio.post(
          "https://dashboard.livair.io/api/livAir/warning",
          data: jsonEncode(
              {
                "deviceId": selectedDevice,
                "radonUpperThreshold": int.parse(thresholdController.text),
                "radonAlarmDuration": selectedHours*60+selectedMinutes
              }
          ),
      );
    }catch(e){
      print(e);
    }
    selectedMinutes = 0;
    selectedHours = 0;
    thresholdController.text = "";
    selectedDevice = "";
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  deleteWarningDialog() {
    AlertDialog alert = AlertDialog(
      title: Text(AppLocalizations.of(context)!.removeWarningT, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.removeWarningDialog),
          const SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: deleteWarning,
                  style: OutlinedButton.styleFrom(backgroundColor: Color(0xff0099f0)),
                  child: Text(AppLocalizations.of(context)!.removeWarning,style: const TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (){
                    selectedDevice = "";
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xff0099f0))),
                  child: Text(AppLocalizations.of(context)!.cancel,style: const TextStyle(color: Color(0xff0099f0)),),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  deleteWarning() async{
    final token = tbClient.getJwtToken();
    final dio = Dio();

    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    print(selectedDevice);
    try{
      dio.delete(
        "https://dashboard.livair.io/api/livAir/warning/${selectedDevice}",
      );
    }catch(e){
      print(e);
    }
    selectedDevice = "";
    Navigator.pop(context);
    await Future<void>.delayed( const Duration(seconds: 1));
    setState(() {

    });
  }

  Widget setScreen() {
    switch (index) {
      case 0:
        return showWarningsScreen();
      case 1:
        return showDeviceSelectScreen();
      case 2:
        return showSelectThresholdScreen();
      case 3:
        return showSelectDurationScreen();
      default:
        return showWarningsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    var build = FutureBuilder(
        future: getAllWarnings(),
        builder: (context,snapshot){
          return WillPopScope(
              onWillPop: () async{
                return false;
              },
              child: setScreen()
          );
        }
    );
    return build;
  }

}