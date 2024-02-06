
import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvp/pages/warnings_page.dart';
import 'package:mvp/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:mvp/pages/device_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:location/location.dart';

import 'notifications_page.dart';


class DestinationView extends StatefulWidget {


  final ThingsboardClient tbClient;

  const DestinationView({
    super.key,
    required this.tbClient
  });


  @override
  State<DestinationView> createState() => _DestinationViewState(tbClient);
}

class _DestinationViewState extends State<DestinationView> {

  final ThingsboardClient tbClient;

  _DestinationViewState(this.tbClient);

  final Dio dio = Dio();
  final location = Location();

  StreamSubscription<List<ScanResult>>? subscription;
  StreamSubscription<List<int>>? subscriptionToDevice;
  StreamSubscription<dynamic>? btChat;
  Map<String, int> foundAccessPoints = {};
  String selectedWifiAccesspoint = "";
  BluetoothDevice? btDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? readCharacteristic;
  TextEditingController wifiPasswordController = TextEditingController();


  int _currentIndex = 0;
  int screenIndex = 0;
  final storage = const FlutterSecureStorage();
  bool hasCompletedOnBoarding = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;


  Widget setPage(int index) {
    switch (index) {
      case 0:
        return DevicePage(tbClient: tbClient);
      case 1:
        return WarningsPage(tbClient: tbClient);
      case 2:
        return NotificationsPage(tbClient: tbClient);
      case 3:
        return ProfilePage(tbClient: tbClient);
      default:
        return DevicePage(tbClient: tbClient);
    }
  }

  Widget setPageOnBoarding(int index) {
    switch (index) {
      case 0:
        return onBoarding1();
      case 1:
        return onBoarding2();
      case 2:
        return onBoarding3();
      case 3:
        return showQRCodeScreen();
      case 4:
        return showConnectingScreen();
      case 5:
        return deviceWifiSelectScreen();
      case 6:
        return deviceWifiPasswordScreen();
      default:
        return onBoarding1();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: hasDoneOnBoarding(),
      builder: (context,snapshot) {
        return hasCompletedOnBoarding ? WillPopScope(
          onWillPop: () async { return false;},
          child: Scaffold(
            body: Center(
              child: setPage(_currentIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: const Color(0xffeff0f1),
              showUnselectedLabels: true,
              unselectedItemColor: Colors.black,
              selectedItemColor: Colors.black,
              currentIndex: _currentIndex,
              onTap: (int newIndex) {
                setState(() {
                  _currentIndex = newIndex;
                });
              },
              items: [
                BottomNavigationBarItem(icon: const SizedBox(width:24,height:28,child: ImageIcon(AssetImage('lib/images/devices.png'),color: Colors.black)), label: AppLocalizations.of(context)!.devices),

                BottomNavigationBarItem(icon: const SizedBox(width:24,height:28,child: ImageIcon(AssetImage('lib/images/warnings.png'),color: Colors.black)), label: AppLocalizations.of(context)!.warnings,),

                BottomNavigationBarItem(icon: const SizedBox(width:24,height:28,child: ImageIcon(AssetImage('lib/images/notifications.png'),color: Colors.black)), label: AppLocalizations.of(context)!.notifications),

                BottomNavigationBarItem(icon: const SizedBox(width:24,height:28,child: ImageIcon(AssetImage('lib/images/profile.png'),color: Colors.black)), label: AppLocalizations.of(context)!.profile)
              ],
            ),
          ),
        ) : Scaffold(
          body: Center(
            child: setPageOnBoarding(screenIndex),
          ),
        );
      }
    );
  }

  hasDoneOnBoarding()async{
    hasCompletedOnBoarding = await storage.containsKey(key: 'hasCompletedOnBoarding');
  }

  onBoarding1(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('lib/images/livAir.png'),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.welcome+" !",style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20,),
                  Text(AppLocalizations.of(context)!.onBoardingDialog1,style: const TextStyle(fontSize: 18)),
                ],
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            screenIndex = 1;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                            side: null,
                            foregroundColor: Color(0xff0099f0),
                            backgroundColor: Color(0xff0099f0),
                            minimumSize: Size(60,50)
                        ),
                        child: Text(AppLocalizations.of(context)!.letsGo  ,style: const TextStyle(color: Colors.white),)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20,),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () async{
                          await storage.write(key: 'hasCompletedOnBoarding', value: 'value');
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(60,50)
                        ),
                        child: Text(AppLocalizations.of(context)!.continueWithoutDevice  ,style: const TextStyle(color: Color(0xff0099f0)),)
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  onBoarding2(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('lib/images/unpack.png'),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.unpackDevice,style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20,),
                  Text(AppLocalizations.of(context)!.onBoardingDialog2,style: const TextStyle(fontSize: 18)),
                ],
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0,20.0,20.0,0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 72,),
                  const ImageIcon(AssetImage('lib/images/onBoardingSlider1.png')),
                  TextButton(
                      onPressed: (){
                        setState(() {
                          screenIndex = 2;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.contin)
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  onBoarding3(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('lib/images/searchPicture.png'),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ImageIcon(AssetImage('lib/images/qrCode.png'),size: 52,),
                  const SizedBox(height: 20,),
                  Text(AppLocalizations.of(context)!.scanCode,style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400)),
                  TextButton(
                    onPressed: (){
                      AlertDialog alert = AlertDialog(
                        title: Text(AppLocalizations.of(context)!.findCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset('lib/images/findCode1.png'),
                                const SizedBox(width: 5,),
                                Image.asset('lib/images/findCode2.png'),
                              ],
                            ),
                            const SizedBox(height: 30,),
                            Text(AppLocalizations.of(context)!.findCodeDialog, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
                            const SizedBox(height: 20,),
                          ],
                        ),
                      );
                      showDialog(
                        context: context,
                        builder: (BuildContext context){
                          return alert;
                        },
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.findCode,style: const TextStyle(fontSize: 14,color: Color(0xff0099f0),decoration: TextDecoration.underline)),
                  )
                ],
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0,0.0,20.0,0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(height: 10,),
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () async{
                          setState(() {
                            screenIndex = 3;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(60,50)
                        ),
                        child: Text(AppLocalizations.of(context)!.scanForCode  ,style: const TextStyle(color: Color(0xff0099f0)),)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                children: [
                  const SizedBox(height: 10,),
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () async{
                          await storage.write(key: 'hasCompletedOnBoarding', value: 'value');
                          setState(() {
                          });
                        },
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(60,50)
                        ),
                        child: Text(AppLocalizations.of(context)!.addDevManually  ,style: const TextStyle(color: Color(0xff0099f0)),)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageIcon(AssetImage('lib/images/onBoardingSlider2.png')),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  showQRCodeScreen(){
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: QRView(
              key: qrKey,
              onQRViewCreated: qrViewController,
              overlay: QrScannerOverlayShape(
                cutOutSize: scanArea,
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
              ),
          ),
        ),
      ],
    );
  }

  qrViewController(QRViewController controller){
    controller = controller;
    controller.resumeCamera();
    StreamSubscription? sub;
    sub = controller.scannedDataStream.listen((scanData) {
      result = scanData;
      setState(() {
        screenIndex = 4;
      });
      sub!.cancel();
      controller.dispose();
    });
  }

  showConnectingScreen(){
    return FutureBuilder(
      future: connectWithBluetooth(),
      builder: (context,snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(result!.code!,style: const TextStyle(color: Colors.black),),
              Text(AppLocalizations.of(context)!.searchingDevAndWifi1  ,style: const TextStyle(color: Colors.black),),
              Text(AppLocalizations.of(context)!.searchingDevAndWifi2  ,style: const TextStyle(color: Colors.black),)
            ],
          ),
        );
      }
    );
  }


  connectWithBluetooth() async{
    int foundAccesspointCount = 0;
    int counter = 0;
    foundAccessPoints = {};
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
          if(bluetoothDeviceName == result!.code!) {
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
                        setState(() {
                          screenIndex = 5;
                        });
                      }
                    }
                    if(message == 'Connect Success'){
                      btDevice!.disconnect(timeout: 1);
                      subscriptionToDevice?.cancel();
                      subscription?.cancel();
                      await storage.write(key: 'hasCompletedOnBoarding', value: 'value');
                      setState(() {
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
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
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
            Text(AppLocalizations.of(context)!.connectToWifiT, style: const TextStyle(color: Colors.black),),
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
                          screenIndex = 6;
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
            Text(AppLocalizations.of(context)!.connectToWifiT, style: TextStyle(color: Colors.black),),
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
}