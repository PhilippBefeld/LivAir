import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mvp/components/my_button.dart';
import 'package:mvp/components/my_textfield.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

import 'package:mvp/components/data/asset.dart';
import 'package:mvp/components/data/organization.dart';

class OrganizationPage extends StatefulWidget {


  final ThingsboardClient tbClient;


  const OrganizationPage({
    super.key,
    required this.tbClient
  });


  @override
  State<OrganizationPage> createState() => _OrganizationPageState(tbClient);

}

class _OrganizationPageState extends State<OrganizationPage> {

  final ThingsboardClient tbClient;
  final logger = Logger();
  final TextEditingController controllerOrgName = TextEditingController();

  _OrganizationPageState(this.tbClient);

  Organization? organization ;
  bool addedOrganization = false;
  int pageIndex = 0;
  
  getOrganizationDetails()async{
    final token = tbClient.getJwtToken();

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(
            'wss://dashboard.livair.io/api/ws/plugins/telemetry?token=$token'),
      );
      channel.sink.add(
          jsonEncode({
            "attrSubCmds": [],
            "tsSubCmds": [],
            "historyCmds": [],
            "entityDataCmds": [
              {
                "query": {
                  "entityFilter": {
                    "type": "singleEntity",
                    "singleEntity": {
                      "id": tbClient.getAuthUser()!.customerId,
                      "entityType": "CUSTOMER"
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
                      "key": "logo"
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
                      "key": "isMain"
                    }
                  ]
                },
                "cmdId": 2
              },
              {
                "query": {
                  "entityFilter": {
                    "type": "singleEntity",
                    "singleEntity": {
                      "id": tbClient.getAuthUser()!.customerId,
                      "entityType": "CUSTOMER"
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
                      "key": "address"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "locationsCount"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "devicesCount"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "language"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "timeFormat"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "radon"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "temperature"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "pressure"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "length"
                    },
                    {
                      "type": "ATTRIBUTE",
                      "key": "calibration"
                    }
                  ]
                },
                "cmdId": 3
              },
            ],
            "entityDataUnsubscribeCmds": [],
            "alarmDataCmds": [],
            "alarmDataUnsubscribeCmds": [],
            "entityCountCmds": [],
            "entityCountUnsubscribeCmds": [],
            "alarmCountCmds": [],
            "alarmCountUnsubscribeCmds": []
          })
      );
      String label = "";
      String name = "";
      int assetCount = 0;
      String language;
      String radonUnit;
      String temperatureUnit;
      String pressureUnit;
      String organizationId = "";
      Asset2 mainLocation = Asset2(name: "name", id: "id", isMain: false, label: "label");
      int deviceCount = 0;
      List<Asset2> assetList = [];

      channel.stream.listen(
              (message) {
                print(message.toString());
                var data = jsonDecode(message)["data"];
                if(data !=null && data["data"]!=[] && jsonDecode(message)["cmdId"] == 1){
                  try{
                    label = data["data"][0]["latest"]["ENTITY_FIELD"]["label"]["value"];
                  }catch(e){
                    label = "";
                    logger.e(e);
                  }
                  name = data["data"][0]["latest"]["ENTITY_FIELD"]["name"]["value"];
                  organizationId = data["data"][0]["entityId"]["id"];
                }
                if(data !=null && jsonDecode(message)["cmdId"] == 2){
                  try{
                    List assets = data["data"];
                    assetCount = assets.length;
                    if(assetCount>0){
                      for(var asset in assets){
                        String assetName = asset["latest"]["ENTITY_FIELD"]["name"]["value"];
                        String assetLabel = asset["latest"]["ENTITY_FIELD"]["label"]["value"];
                        String assetId = asset["entityId"]["id"];
                        String assetIsMain = asset["latest"]["ATTRIBUTE"]["isMain"]["value"];
                        Asset2 currentAsset = Asset2(
                            name: assetName,
                            id: assetId,
                            isMain: bool.parse(assetIsMain),
                            label: assetLabel
                        );
                        assetList.add(currentAsset);
                        if(bool.parse(assetIsMain)){
                          mainLocation = currentAsset;
                        }
                      }
                    }
                  }catch(e){
                    logger.e(e);
                  }
                }
                if(data !=null && jsonDecode(message)["cmdId"] == 3){
                  try{
                    language = data["data"][0]["latest"]["ATTRIBUTE"]["language"]["value"];
                    radonUnit = data["data"][0]["latest"]["ATTRIBUTE"]["radon"]["value"];
                    pressureUnit = data["data"][0]["latest"]["ATTRIBUTE"]["pressure"]["value"];
                    temperatureUnit = data["data"][0]["latest"]["ATTRIBUTE"]["temperature"]["value"];
                    deviceCount = int.parse(data["data"][0]["latest"]["ATTRIBUTE"]["devicesCount"]["value"]);

                  }catch(e){
                    logger.e(e);
                  }
                  try{
                    organization = Organization(
                        name: name,
                        label: label,
                        deviceCount: deviceCount,
                        id: organizationId,
                        locationCount: assetCount,
                        mainLocation: mainLocation,
                        assetList: assetList
                    );
                    if(!addedOrganization) {
                      addedOrganization = true;
                      setState(() {
                      });
                    }
                  }catch(e){
                    logger.e(e);
                  }
                }
              }
      );
    }catch(e){
      logger.e(e);
    }
  }

  Widget setPage(int index) {
    switch (index) {
      case 0:
        return Column();
      default:
        return Column();
    }
  }

  orgMainPage(){
    return Column(
      children: [
        Row(
          children: [
            Text("Oranization name"),
            Flexible(
                child: MyTextField(
                    controller: controllerOrgName,
                    hintText: "Oranization name",
                    obscureText: false,
                    onChanged: null,
                    initialValue: organization == null ? "" : organization!.name
                )
            ),
          ],
        ),
        Row(
          children: [
            const Text("Oranization ID"),
            MyButton(width: 240.00, onTap: null, textInhalt: organization == null ? "" :organization!.id),
          ],
        ),
        Row(
          children: [
            const Text("Locations"),
            MyButton(width: 240.00,onTap: null, textInhalt: organization == null ? "" : "${organization!.locationCount} Location${organization!.locationCount>1 ||organization!.locationCount==0 ? "s": ""}"),
          ],
        ),
        Row(
          children: [
            const Text("Main location"),
            MyButton(width: 240.00,onTap: null, textInhalt: organization == null ? "" :organization!.mainLocation.name),
          ],
        ),
        Row(
          children: [
            const Text("Devices"),
            MyButton(width: 240.00,onTap: null, textInhalt: organization == null ? "" : "${organization!.deviceCount} Device${organization!.deviceCount >1 ||organization!.deviceCount==0 ? "s": ""}"),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context){
    var build =
        FutureBuilder(
            future: getOrganizationDetails(),
            builder: (context,snapshot){
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: setPage(pageIndex)
                  ),
                ),
              );
            }
        );
    return build;
  }
}