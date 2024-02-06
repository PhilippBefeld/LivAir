
import 'package:flutter/material.dart';
import 'package:mvp/components/my_button.dart';
import 'package:mvp/components/my_device_widget.dart';
import 'package:mvp/pages/device_detail_page.dart';
import 'package:mvp/components/data/device.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';


class LocationsPage extends StatefulWidget {


  final ThingsboardClient tbClient;

  const LocationsPage({
    super.key,
    required this.tbClient
  });


  @override
  State<LocationsPage> createState() => _LocationsPageState(tbClient);
}

class _LocationsPageState extends State<LocationsPage> {

  final ThingsboardClient tbClient;
  final logger = Logger();

  _LocationsPageState(this.tbClient);


  List<Map<String,List<Map<String,Device2>>>> currentDevicesPerAsset = [];
  List<String> namesPerAsset = [];
  List<Map<String,Device2>> currentDevices = [];
  List<String> currentRadonValues = [];
  int assetCount = 0;


  Future<dynamic> getAllDevices() async{
    final token = tbClient.getJwtToken();
    int messageCount = 0;

    try{
      final channel = WebSocketChannel.connect(
        Uri.parse('wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
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
                  "groupType": "ASSET",
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
                  "key": "floor"
                  },
                  {
                  "type": "ATTRIBUTE",
                  "key": "basementFloor"
                  }
                  ]
                  },
                  "cmdId": 1
                  },
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
      channel.stream.listen(
              (data) {
                messageCount+=1;
                logger.d(data);
                if(messageCount == 2){
                  channel.sink.add(
                    jsonEncode(
                        {
                          "attrSubCmds": [],
                          "tsSubCmds": [],
                          "historyCmds": [],
                          "entityDataCmds": [
                            {
                              "cmdId": 1,
                              "latestCmd": {
                                "keys": [
                                  {
                                    "type": "ATTRIBUTE",
                                    "key": "floor"
                                  },
                                  {
                                    "type": "ATTRIBUTE",
                                    "key": "basementFloor"
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
                    )
                  );
                  channel.sink.add(
                    jsonEncode(
                        {
                          "attrSubCmds": [],
                          "tsSubCmds": [],
                          "historyCmds": [],
                          "entityDataCmds": [
                            {
                              "cmdId":2,
                              "tsCmd": {
                                "keys": [
                                  "temp",
                                  "score",
                                  "radon",
                                  "co2",
                                  "nox",
                                  "humidity",
                                  "voc",
                                  "dust",
                                  "pressure",
                                  "noise",
                                  "light",
                                  "radon1",
                                  "radon2",
                                  "radon3",
                                  "radon4"
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
                List<dynamic> data1 = [];
                if(jsonDecode(data)["data"]!=null)data1= jsonDecode(data)["data"]["data"];
                if(data1.isNotEmpty && jsonDecode(data)["cmdId"] == 1){
                  print("tryaddingasset");
                  for(var element in data1){
                    try{
                      currentDevicesPerAsset.add({element["entityId"]["id"] : []});
                      try{
                        namesPerAsset.add(element["latest"]["ENTITY_FIELD"]["label"]["value"]);
                      }catch(e){
                        namesPerAsset.add(element["latest"]["ENTITY_FIELD"]["name"]["value"]);
                      }
                    }catch(e){
                      logger.e(e);
                    }
                  }
                  assetCount = data1.length;
                }
                List<dynamic> updateData = [];
                if(jsonDecode(data)["update"]!=null)updateData = jsonDecode(data)["update"];
                if(updateData.isNotEmpty && jsonDecode(data)["cmdId"] == 2){
                  for (var element in updateData) {
                    try{
                      //check if radon values are sent
                      var newestRadonValue;
                      try {
                        List<
                            dynamic> radonValues = element["timeseries"]["radon"];
                        if (radonValues.isNotEmpty) {
                          Map<String, dynamic> newestRadonInfo = radonValues
                              .elementAt(0);
                          newestRadonValue = newestRadonInfo["value"];
                        }
                      }catch(e){
                        logger.e(e);
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
                        logger.e(e);
                      }
                      //check if lastSync is transmitted
                      String lastSync = "0";
                      try{
                        lastSync = attributes["lastSync"]["value"];
                        if(lastSync == "")lastSync = "0";
                      }catch(e){
                        logger.e(e);
                      }
                      bool elementFound = false;

                      for (Map<String,List<Map<String,Device2>>> asset in currentDevicesPerAsset) {
                        try{
                          if(asset.containsKey(attributes["locationId"]["value"])){
                            List<Map<String,Device2>>? devicesToCheck = asset[attributes["locationId"]["value"]];
                            if(devicesToCheck != [] && devicesToCheck != null) {
                              for (var deviceMap in devicesToCheck) {
                                if(deviceMap.keys.first == deviceId){
                                  elementFound = true;
                                  deviceMap.values.first.update(
                                    lastSync == "0" ? null : int.parse(lastSync),
                                    attributes["location"]["value"],
                                    attributes["floor"]["value"],
                                    attributes["locationId"]["value"],
                                    bool.parse(attributes["isOnline"]["value"]),
                                    newestRadonValue != null ? int.parse(newestRadonValue) : null,
                                    label ?? "",
                                    deviceInfo["name"]["value"],
                                  );
                                }
                            }
                            }
                          }
                        }catch(e){
                          logger.e(e);
                        }
                      }

                      if(!elementFound) {
                        for(Map<String,List<Map<String,Device2>>> asset in currentDevicesPerAsset) {
                          if(asset.containsKey(attributes["locationId"]["value"])) {
                            asset.values.first.add({
                              deviceId : Device2(
                                lastSync: int.parse(lastSync),
                                location: attributes["location"]["value"],
                                floor: attributes["floor"]["value"],
                                locationId: attributes["locationId"]["value"],
                                isOnline: bool.parse(attributes["isOnline"]["value"]),
                                radon: int.parse(newestRadonValue ?? "0"),
                                label: label ?? "",
                                name: deviceInfo["name"]["value"],
                                deviceAdded:  attributes["deviceAdded"]["value"],
                              )
                            });
                          }
                        }
                      }
                    }catch(e){
                      logger.e(e);
                    }
                  }
                }
              }
      );
    }catch(e){
      logger.e(e);
    }
  }

  void showDeviceDetails(Map<String,Device2> device){
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => DeviceDetailPage(tbClient: tbClient, device: device)
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    var build =  FutureBuilder(
        future: getAllDevices(),
        builder: (context,snapshot) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20,),
                    Expanded(
                        child: ListView.separated(
                            separatorBuilder: (context, index) => SizedBox(height: 10,),
                            padding: const EdgeInsets.only(bottom: 10),
                            itemBuilder: (BuildContext context, int index) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                separatorBuilder: (context, index1) => SizedBox(height: 10,),
                                padding: const EdgeInsets.only(bottom: 10),
                                itemCount: currentDevicesPerAsset[index].values.first.length+1,
                                itemBuilder: (BuildContext context, int index2) {
                                  if(index2 == 0){
                                    return MyButton(onTap: null, textInhalt: namesPerAsset[index],heigth:50 ,width: 170.0,padding: const EdgeInsets.all(10),alignment: Alignment.centerLeft,);
                                  }
                                  return MyDeviceWidget(
                                    onTap: (){
                                      showDeviceDetails({currentDevicesPerAsset[index].values.first[index2-1].values.first.locationId : currentDevicesPerAsset[index].values.first[index2-1].values.first});
                                      },
                                    name: currentDevicesPerAsset[index].values.first[index2-1].values.first.name,
                                    isOnline: currentDevicesPerAsset[index].values.first[index2-1].values.first.isOnline,
                                    radonValue: currentDevicesPerAsset[index].values.first[index2-1].values.first.radon.toString(),
                                    unit: "",
                                  );
                                },
                              );
                            },
                            itemCount: assetCount
                        )
                    )
                  ],
                ),
              ),
            )
          );
        }
    );
    return build;
  }
}
