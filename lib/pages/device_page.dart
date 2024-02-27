
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:mvp/components/my_device_widget.dart';
import 'package:mvp/pages/device_detail_page.dart';
import 'package:mvp/components/data/device.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:logger/logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:location/location.dart';

class DevicePage extends StatefulWidget {

  final ThingsboardClient tbClient;

  const DevicePage({super.key, required this.tbClient});

  @override
  State<DevicePage> createState() => DevicePageState(tbClient);
}

class DevicePageState extends State<DevicePage> {

  final ThingsboardClient tbClient;
  final logger = Logger();
  final Dio dio = Dio();
  final location = Location();
  final storage = FlutterSecureStorage();
  String? unit;

  DevicePageState( this.tbClient);
  DeviceResponse pagingInfo = DeviceResponse(0,0);
  List<Map<String,dynamic>> currentDevices = [];
  List<Map<String,Device2>> currentDevices2 = [];
  List<String> currentRadonValues = [];
  bool searchedAdditionalDevices = false;

  List<DropdownMenuItem<String>> locationsDropdownMenuItems = [const DropdownMenuItem<String>(value: "Wähle einen Standort", child: Text("Wähle einen Standort"))];
  List<DropdownMenuItem<String>> floorsOfLocationDropdownMenuItems = [const DropdownMenuItem<String>(value: "Wähle ein Stockwerk", child: Text("Wähle ein Stockwerk"))];
  Map<String, List<DropdownMenuItem<String>>> floorsPerLocationDropdownMenuItems = {};
  WebSocketChannel? channel;

  //Screen control variables
  int screenIndex = 0;

  //addDevice variables
  StreamSubscription<List<ScanResult>>? subscription;
  StreamSubscription<dynamic>? btChat;
  List<BluetoothDevice>? foundDevices;
  List<String>? foundDevicesIds;
  BluetoothDevice? deviceToAdd;
  Map<String, int> foundAccessPoints = {};
  String selectedWifiAccesspoint = "";
  String newDeviceId = "";
  TextEditingController newDeviceIdController = TextEditingController();
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  TextEditingController wifiPasswordController = TextEditingController();
  TextEditingController deviceNameController = TextEditingController();
  String newDeviceName = "";
  TextEditingController deviceLocationController = TextEditingController();
  String newDeviceLocation = "";

  Future<dynamic> getAllDevices() async{
    if(channel != null) return;
    final token = tbClient.getJwtToken();
    searchedAdditionalDevices = false;
    var firstTry = true;
    unit = await storage.read(key: 'unit');
    try{
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        }
      } on SocketException catch (_) {
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.noInternetT
        );
        return;
      }
      channel = WebSocketChannel.connect(
        Uri.parse('wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
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
                      },
                      {
                        "type": "ENTITY_FIELD",
                        "key": "additionalInfo"
                      }
                    ],
                    "latestValues": [
                      {
                        "type": "ATTRIBUTE",
                        "key": "lastSync"
                      },
                      {
                        "type": "ATTRIBUTE",
                        "key": "location"
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
                        "key": "locationId"
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
      channel!.stream.listen(
              (data) async{
                if(firstTry){
                  logger.d(data);
                  firstTry = false;
                  channel!.sink.add(
                    jsonEncode(
                      {
                        "attrSubCmds": [],
                        "tsSubCmds": [],
                        "historyCmds": [],
                        "entityDataCmds": [
                          {
                            "cmdId":1,
                            "tsCmd": {
                              "keys": [
                                "radon",
                              ],
                              "startTs": DateTime.now().millisecondsSinceEpoch-901000,
                              "timeWindow": 901000,
                              "interval": 1000,
                              "limit": 50000,
                              "agg": "NONE"
                            },
                            "latestCmd": {
                              "keys": [
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "lastSync"
                                },
                                {
                                  "type": "ATTRIBUTE",
                                  "key": "location"
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
                                  "key": "locationId"
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
                    ),
                  );
                }

                List<dynamic> updateData = [];
                if(jsonDecode(data)["update"]!=null)updateData = jsonDecode(data)["update"];
                if(updateData.isNotEmpty){
                  for (var element in updateData) {
                    try{
                      //check if radon values are sent
                      var newestRadonValue = "0";
                      try {
                        List<dynamic> radonValues = element["timeseries"]["radon"];
                        if (radonValues.isNotEmpty) {
                          Map<String, dynamic> newestRadonInfo = radonValues
                              .elementAt(0);
                          newestRadonValue = newestRadonInfo["value"];
                        }
                      }catch(e){
                      }
                      //get the deviceId
                      String deviceId = element["entityId"]["id"];
                      //get requested attributes(lastSync,isOnline,floor,etc)
                      Map<String, dynamic> attributes = element["latest"]["ATTRIBUTE"];
                      //get requested device info(name,label,etc)
                      Map<String, dynamic> deviceInfo = element["latest"]["ENTITY_FIELD"];
                      //check if device has label
                      String? label;
                      try{
                        label = deviceInfo["label"]["value"];
                      }catch(e){
                      }
                      DateTime? deviceAdded;
                      try{
                        deviceAdded = DateTime.parse(attributes["deviceAdded"]["value"]);
                      }catch(e){
                      }
                      //check if lastSync is transmitted
                      String lastSync = "0";
                      try{
                        lastSync = attributes["lastSync"]["value"];
                        if(lastSync == "")lastSync = "0";
                      }catch(e){
                      }
                      bool elementFound = false;
                      currentDevices2.forEach((element) {
                        try{
                          if(element.containsKey(deviceId)){
                            elementFound = true;
                            element.values.first.update(
                                lastSync == "0" ? null : int.parse(lastSync),
                                attributes["location"]["value"],
                                "",
                                "",
                                bool.parse(attributes["isOnline"]["value"]),
                                newestRadonValue != null ? int.parse(newestRadonValue) : null,
                                label ?? "",
                                deviceInfo["name"]["value"]
                            );
                          }
                        }catch(e){
                        }
                      });
                      if(!elementFound) {
                        currentDevices2.add({
                        deviceId.toString() : Device2(
                            lastSync : int.parse(lastSync),
                            location : attributes["location"]["value"],
                            floor : "",
                            locationId : "",
                            isOnline : bool.parse(attributes["isOnline"]["value"]),
                            radon : int.parse(newestRadonValue),
                            label : label ?? "",
                            name : deviceInfo["name"]["value"],
                            deviceAdded: 1,
                        )
                      });
                      }
                    }catch(e){
                    }
                  }
                  channel!.sink.close();
                }
                dio.options.headers['content-Type'] = 'application/json';
                dio.options.headers['Accept'] = "application/json";
                dio.options.headers['Authorization'] = "Bearer $token";
                if(!searchedAdditionalDevices){
                  searchedAdditionalDevices = true;
                  try {
                    var result = await dio.get('https://dashboard.livair.io/api/user/devices',
                        queryParameters:
                        {
                          "pageSize": 1000,
                          "page": 0
                        }
                    );
                    Map<String,dynamic> map = result.data;
                    List list = map["data"];
                    for (var element in list) {
                      bool found = false;
                      for( var element2 in currentDevices2){
                        if(element2.keys.first == element["id"]["id"]){
                          found = true;
                        }
                      }
                      if(!found){
                        var result2 = await dio.get('https://dashboard.livair.io/api/plugins/telemetry/DEVICE/${element["id"]["id"]}/values/timeseries',
                            queryParameters:
                            {
                              "keys": "radon"
                            }
                        );
                        print(result2);
                        currentDevices2.add({
                          element["id"]["id"].toString() : Device2(
                            lastSync : 0,
                            location : "/",
                            floor : "viewer",
                            locationId : "/",
                            isOnline : false,
                            radon : int.parse(result2.data["radon"].elementAt(0)["value"]),
                            label : element["label"],
                            name : element["name"],
                            deviceAdded: 1,
                          )
                        });
                      }
                    }
                    setState(() {

                    });
                  }catch(e){
                    print(e);
                  }
                }
              }
      );
    }catch(e){

    }
  }

  void showDeviceDetails(Map<String,Device2> device){
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => DeviceDetailPage(tbClient: tbClient, device: device)
        )
    );
  }


  Widget setPage(){
    switch(screenIndex){
      case 0: return deviceScreen();
      case 1: return claimDeviceScreen();
      case 11: return deviceWifiSelectScreen();
      case 12: return deviceWifiPasswordScreen();
      case 13: return deviceNameScreen();
      case 14: return deviceLocationScreen();
      case 15: return deviceScreenManual();
      default: return deviceScreen();
    }
  }

  deviceNameScreen(){
    if(btChat!=null)btChat!.cancel();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 12;
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.chooseMeaningfulName,style: const TextStyle(fontSize: 16),),
            const SizedBox(height: 30,),
            Text(AppLocalizations.of(context)!.deviceName),
            const SizedBox(height: 5,),
            TextField(
              controller: deviceNameController,
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: AppLocalizations.of(context)!.egKitchen,
                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
              ),
            ),
            const SizedBox(height: 30,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: (){
                        newDeviceName = deviceNameController.text;
                        setState(() {
                          screenIndex = 14;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.contin)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  sendDeviceClaimRequest() async{
    final token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    try{
      await dio.post('https://dashboard.livair.io/api/livAir/claim',
          data:
          {
            "claimingKey": newDeviceId,
            "deviceName": newDeviceName,
            "location": newDeviceLocation
          }
      );
      setState(() {
        screenIndex = 0;
      });
    }on DioError catch(e){
      print(e);
      setState(() {
        screenIndex = 0;
      });
    }
  }

  deviceLocationScreen(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 0;
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
            const SizedBox(height: 10,),
            Text(AppLocalizations.of(context)!.locationDialog),
            const SizedBox(height: 30,),
            Text(AppLocalizations.of(context)!.deviceLocation),
            const SizedBox(height: 5,),
            TextField(
              controller: deviceLocationController,
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                fillColor: Colors.white,
                filled: true,
                hintText: AppLocalizations.of(context)!.locationHint,
                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
              ),
            ),

            GooglePlaceAutoCompleteTextField(
              textEditingController: deviceLocationController,
              googleAPIKey: "AIzaSyAxry8f1YCKcXgQh6LOgCESzckFyryAgXE",
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
                              msg: AppLocalizations.of(context)!.noInternetT
                          );
                          return;
                        }
                        newDeviceLocation = deviceLocationController.text;
                        sendDeviceClaimRequest();
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          minimumSize: const Size(60,50)
                      ),
                      child: Text(AppLocalizations.of(context)!.finish)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  deviceWifiPasswordScreen(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            deviceToAdd!.disconnect(timeout: 1);
            btChat!.cancel();
            setState(() {
              screenIndex = 11;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
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
                  borderSide: BorderSide(width: 2,color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2,color: Colors.black),
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
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 0),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
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

  deviceWifiSelectScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            deviceToAdd!.disconnect(timeout: 1);
            btChat!.cancel();
            setState(() {
              screenIndex = 1;
            });
          },
        ),
        title: Text(AppLocalizations.of(context)!.connectToWifiT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index){
                  return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          screenIndex = 12;
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
          ),
        ],
      ),
    );
  }

  claimDeviceScreen2() async{
    int foundAccesspointCount = 0;
    int counter = 0;
    foundAccessPoints = {};

    await deviceToAdd!.connect();
    await deviceToAdd!.requestMtu(100);
    List<BluetoothService> services = await deviceToAdd!.discoverServices();
    for (var service in services){
      for(var characteristic in service.characteristics){
        if(characteristic.properties.notify){
          await characteristic.setNotifyValue(true);
          readCharacteristic = characteristic;
          btChat = characteristic.lastValueStream.listen((data) async{
            String message = utf8.decode(data).trim();
            print(utf8.decode(data));
            if(message == ""){
              await Future<void>.delayed( const Duration(seconds: 1));
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
                if(foundAccesspointCount ==0){
                  setState(() {
                    screenIndex = 0;
                  });
                  Fluttertoast.showToast(
                      msg: "No access points found"
                  );
                }
                setState(() {
                  screenIndex = 11;
                });
              }
            }
            if(message == "Connect Success"){
              deviceToAdd!.disconnect(timeout: 1);
              setState(() {
                screenIndex = 13;
              });
            }
          });
        }
        if(characteristic.properties.write){
          writeCharacteristic = characteristic;
          await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
        }
      }
    }
  }



  searchAvailableDevices() async{
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      }
    } on SocketException catch (_) {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.noInternetT
      );
      return;
    }
    foundDevices = [];
    foundDevicesIds = [];

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
    FlutterBluePlus.scanResults.timeout( const Duration(seconds: 2));
    var subscription = FlutterBluePlus.scanResults.listen((results) async{
      for(ScanResult r in results){
        if(r.advertisementData.manufacturerData.keys.first == 3503){
          List<int> data = r.advertisementData.manufacturerData.values.elementAt(0).sublist(15,23);
          Iterable<int> dataIter = data;

          if(!foundDevicesIds!.contains(String.fromCharCodes(dataIter))){
            foundDevicesIds!.add(String.fromCharCodes(dataIter));
            foundDevices!.add(r.device);
          }
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
    await Future<void>.delayed( const Duration(seconds: 4));
    subscription.cancel();
    if(foundDevices!.isEmpty){
      screenIndex = 0;
      Fluttertoast.showToast(
          msg: "No devices found"
      );
      return;
    }
    setState(() {
      screenIndex = 1;
    });
  }

  claimDeviceScreen(){
    if(foundDevicesIds!.isEmpty){
      setState(() {
        screenIndex = 0;
      });
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: (){
            setState(() {
              screenIndex = 0;
            });
          },
        ),
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: Text(AppLocalizations.of(context)!.visibleDevicesT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 1,),
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: foundDevicesIds!.length,
              itemBuilder: (BuildContext context, int index) {
                String? ifHasLabel;
                for (var element in currentDevices2) {
                  if(element.values.first.name.toUpperCase() == foundDevicesIds![index]){
                    ifHasLabel = element.values.first.label;
                  }
                }
                return OutlinedButton(
                    onPressed: (){
                      newDeviceId = foundDevicesIds![index];
                      deviceToAdd = foundDevices![index];
                      claimDeviceScreen2();
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
                        Text(ifHasLabel ?? foundDevicesIds![index], style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400),),
                      ],
                    )
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: OutlinedButton(
                    onPressed: (){
                      newDeviceName = deviceNameController.text;
                      setState(() {
                        screenIndex = 15;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 0),
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      minimumSize: const Size(60,50)
                    ),
                    child: Text(AppLocalizations.of(context)!.addDevManually,style: const TextStyle(color: Colors.black),)
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  deviceScreenManual(){
    return FutureBuilder(
        future: getAllDevices(),
        builder: (context,snapshot) {
          return Scaffold(
            appBar: AppBar(
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
              titleTextStyle: const TextStyle(color: Colors.black),
              title: Text(AppLocalizations.of(context)!.addDevManuallyT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
            ),
            body: SafeArea(
              child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10,),
                            Text(AppLocalizations.of(context)!.deviceIDDialog),
                            const SizedBox(height: 30,),
                            TextField(
                              controller: newDeviceIdController,
                              decoration: InputDecoration(
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(width: 2,color: Colors.black),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(width: 2,color: Colors.black),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: AppLocalizations.of(context)!.deviceIDHint,
                                hintStyle: TextStyle(color: Colors.grey[500],fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                  onPressed: (){
                                    newDeviceId = newDeviceIdController.text;
                                    setState(() {
                                      screenIndex = 13;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(width: 0),
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(60,50)
                                  ),
                                  child: Text(AppLocalizations.of(context)!.contin,style: const TextStyle(color: Colors.black),)
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
              ),
            ),
          );
        }
    );
  }
  
  deviceScreen(){
    return FutureBuilder(
        future: getAllDevices(),
        builder: (context,snapshot) {
          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
              titleTextStyle: const TextStyle(color: Colors.black),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    onPressed: () async{
                      try {
                        final result = await InternetAddress.lookup('example.com');
                        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                        }
                      } on SocketException catch (_) {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)!.noInternetT
                        );
                        return;
                      }
                      searchAvailableDevices();
                    },
                    icon: const Icon(MaterialSymbols.add,color: Color(0xff0099f0),)
                ),
              ],
              elevation: 0,
              title: Text(AppLocalizations.of(context)!.allDevicesT,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Center(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          separatorBuilder: (context, index) => const SizedBox(height: 10,),
                          padding: const EdgeInsets.only(bottom: 10),
                          itemCount: currentDevices2.length,
                          itemBuilder: (BuildContext context, int index) {
                            return MyDeviceWidget(
                              onTap: () async{
                                  try {
                                    final result = await InternetAddress.lookup('example.com');
                                    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                                    }
                                  } on SocketException catch (_) {
                                    Fluttertoast.showToast(
                                        msg: AppLocalizations.of(context)!.noInternetT
                                    );
                                    return;
                                  }
                                showDeviceDetails(currentDevices2[index]);
                              },
                              name: currentDevices2[index].values.elementAt(0).floor == "viewer" ?  "${currentDevices2[index].values.elementAt(0).label} (as Viewer)" : currentDevices2[index].values.elementAt(0).label!,
                              isOnline: currentDevices2[index].values.elementAt(0).isOnline,
                              radonValue: currentDevices2[index].values.elementAt(0).radon.toString(),
                              unit: unit == "Bq/m³" ? "Bq/m³": "pCi/L",
                            );
                          },
                        ),
                      ),
                    ],
                  )
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
   return WillPopScope(
       onWillPop: () async{
         return false;
       },
       child: setPage()
   );
  }
}

class DeviceResponse {
  final int deviceCount;
  final int pageCount;

  DeviceResponse(this.deviceCount, this.pageCount);

  DeviceResponse.fromJson(Map<String, dynamic> json)
        :deviceCount = json['totalElements'],
        pageCount = json['totalPages'];
}
