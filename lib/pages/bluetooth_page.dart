import 'dart:convert';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPage extends StatefulWidget {
  final ThingsboardClient tbClient;

  const BluetoothPage({super.key, required this.tbClient});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState(tbClient);
}

class _BluetoothPageState extends State<BluetoothPage> {

  final ThingsboardClient tbClient;
  final logger = Logger();
  final location = Location();

  Map<String,BluetoothDevice> currentBluetoothDevices = {};

  bool searchDone = false;

  final textEditingController = TextEditingController();
  List<DropdownMenuItem<String>> foundAccessPoints = [const DropdownMenuItem<String>(value: "Zugangspunkt wählen", child: Text("Zugangspunkt wählen"))];

  _BluetoothPageState(this.tbClient);


  connect(BluetoothDevice device) async{
    foundAccessPoints = [const DropdownMenuItem<String>(value: "Zugangspunkt wählen", child: Text("Zugangspunkt wählen"))];
    BluetoothCharacteristic? writeCharacteristic;
    String dropdownValue = 'Zugangspunkt wählen';
    int selectedAccessPointNumber = -1;
    int foundAccessPointsCount = 0;
    int counter = 0;
    bool isScanning = false;

    showDialog(context: context, builder: (context){
      return const Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          )
      );
    });

    device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
      }
    });

    await device.connect();
    await device.requestMtu(100);

    connectDeviceToAccessPoint() async{
      print("CONNECT:$selectedAccessPointNumber,|${textEditingController.text}");
      await writeCharacteristic!.write(utf8.encode("CONNECT:$selectedAccessPointNumber,|${textEditingController.text}"));
    }

    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
        var characteristics = service.characteristics;
        for(BluetoothCharacteristic c in characteristics) {
          if(c.properties.notify){
            await c.setNotifyValue(true);
            c.lastValueStream.listen((data) async{
              String message = utf8.decode(data).trim();
              print(utf8.decode(data));
              if(message == 'LOGIN OK' && !isScanning){
                await writeCharacteristic!.write(utf8.encode('SCAN'));
                isScanning = true;
              }
              if(message.length >=7){
                if(message.substring(0,6) == 'Found:'){
                  isScanning = false;
                  foundAccessPointsCount = int.parse(message.substring(6,message.length));
                }
              }
              if(message.length>= 4 && message.substring(1,3) == ',|'){
                foundAccessPoints.add(DropdownMenuItem<String>(value: message.substring(3,message.indexOf('|',5)-1), child: Text(message.substring(3,message.indexOf(",",4)))));
                counter++;
                if(counter == foundAccessPointsCount){
                  Navigator.pop(context);
                  openDialog() => showDialog(
                      context: context,
                      builder: (context) => FutureBuilder(
                          builder: (context,projectSnap){
                            return AlertDialog(
                                title: const Text('Erfolgreich mit Gerät verbunden'),
                                content: Column(
                                  children: [
                                    const SizedBox(height: 15),
                                    const Text('Zugangspunkte in der Umgebung:'),
                                    const SizedBox(height: 15),
                                    StatefulBuilder(
                                        builder: (BuildContext context,StateSetter setState) {
                                          return DropdownButton<String>(
                                            value: dropdownValue,
                                            items: foundAccessPoints,
                                            onChanged: (value){
                                              setState(() {
                                                if(dropdownValue != value.toString()) dropdownValue = value.toString();
                                                foundAccessPoints.forEach((element) {
                                                  if(element.value == value.toString()){
                                                    selectedAccessPointNumber = (foundAccessPoints.indexOf(element)-1);
                                                  }
                                                });
                                              });
                                            },
                                          );
                                        }
                                    ),
                                    const SizedBox(height: 15),
                                    TextField(
                                      controller: textEditingController,
                                      decoration: const InputDecoration(hintText: 'Zugangspunkt-Passwort'),
                                    ),
                                    TextButton(
                                        onPressed: connectDeviceToAccessPoint,
                                        child: const Text('Hinzufügen')
                                    ),
                                  ],
                                )
                            );
                          }
                      )
                  );
                  openDialog();
                }
              }
              if(message == 'Connect Success'){
                Navigator.pop(context);
                openDialog() => showDialog(
                    context: context,
                    builder: (context) => FutureBuilder(
                        builder: (context,projectSnap){
                          return const AlertDialog(
                              title: Text('Erfolgreich mit Gerät verbunden'),
                              content: Column(
                                children: [
                                  SizedBox(height: 15),
                                  Text('Gerät erfolgreich verbunden'),
                                ],
                              )
                          );
                        }
                    )
                );
                openDialog();
              }
            });
          }
          if(c.properties.write){
            writeCharacteristic = c;
            await writeCharacteristic!.write(utf8.encode('k47t58W43Lds8'));
          }
        }
    });

  }

  searchForDevices() async {
    if(searchDone)return;
    searchDone = true;
    await FlutterBluePlus.turnOn();
    var locationEnabled = await location.serviceEnabled();
    if(!locationEnabled){
      var locationEnabled2 = await location.requestService();
      if(!locationEnabled2){
        Navigator.pop(context);
      }
    }
    var permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
        Navigator.pop(context);
      }
    }

    FlutterBluePlus.stopScan();
    currentBluetoothDevices = {};
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        currentBluetoothDevices.addAll(<String,BluetoothDevice>{r.device.localName: r.device});
        print(r.advertisementData.manufacturerData);
      }
      setState(() {

      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));

  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: searchForDevices(),
        builder: (context,projectSnap){
          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(
                color: Colors.black,
              ),
              backgroundColor: Colors.grey[300],
              titleTextStyle: const TextStyle(color: Colors.black),
              automaticallyImplyLeading: false,
              title: const Text('Geräte'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 10),
                        itemCount: currentBluetoothDevices.length,
                        itemBuilder: (BuildContext context, int index) {
                          return TextButton(
                            onPressed: (){connect(currentBluetoothDevices.values.elementAt(index));},
                            child: Text(currentBluetoothDevices.keys.elementAt(index)),
                          );
                        },
                      ),
                    ),],
                ),
              ),
            ),
          );
        });
  }

}
