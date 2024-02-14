
import 'dart:convert';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_material_symbols/flutter_material_symbols.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:mvp/components/long_Strings/policy.dart';
import 'package:mvp/components/long_Strings/imprint.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../main.dart';

class ProfilePage extends StatefulWidget {

  final ThingsboardClient tbClient;

  ProfilePage({super.key,required this.tbClient});

  @override
  State<ProfilePage> createState() => ProfilePageState(tbClient);
}

class ProfilePageState extends State<ProfilePage>{

  final ThingsboardClient tbClient;
  final Dio dio = Dio();
  final logger = Logger();

  final storage = const FlutterSecureStorage();
  String? unit;
  String? language;


  //screen control variables
  int currentIndex = 0;
  bool showAppBar = false;
  bool gotProfileData = false;
  String appBarTitle = "";

  //personalData variables
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String name = "";
  var responseData = {};

  //Change password variables
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();

  ProfilePageState(this.tbClient);

  //shareDeviceScreen values
  TextEditingController emailController2 = TextEditingController();
  TextEditingController emailController3 = TextEditingController();
  List<dynamic> viewerData = [];
  String emailToRemove = "";
  List<String> deviceIds = [];
  List<String> labels = [];
  List<dynamic> devicesToShare = [];
  String viewerToManage = "";
  List<dynamic> viewerDevicesOld = [];
  List<dynamic> viewerDevicesNew = [];
  List<dynamic> devicesToUnshare = [];

  //deleteAccountScreen variables
  TextEditingController deleteReasonController = TextEditingController();


  getProfileData() async{
    if(!gotProfileData){
      gotProfileData = true;
      unit = await storage.read(key: 'unit');
      language = await storage.read(key: "language");
      final token = tbClient.getJwtToken();
      dio.options.headers['content-Type'] = 'application/json';
      dio.options.headers['Accept'] = "application/json";
      dio.options.headers['Authorization'] = "Bearer $token";

      var response;
      try{
        response = await dio.get("https://dashboard.livair.io/api/user/${tbClient.getAuthUser()!.userId}");
        print(response);
      }catch(e){
        logger.e(e);
      }
      responseData = response!.data;
      nameController.text = responseData["firstName"];
      name = responseData["firstName"];
      emailController.text = responseData["email"];
      setState(() {
      });
    }
  }

  postProfileData() async{
    responseData["firstName"] = nameController.text;
    responseData["email"] = emailController.text;

    try{
      var response = await dio.post("https://dashboard.livair.io/api/user?sendActivationMail=false",
        data: responseData
      );
    }catch(e){
      logger.e(e);
    }
    setState(() {
      getProfileData();
    });
  }

  showPasswordScreen(){
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              Text(AppLocalizations.of(context)!.oldPassword, style: TextStyle(fontSize: 12),),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.start,
                      controller: oldPasswordController,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20,),
              Text(AppLocalizations.of(context)!.newPassord, style: TextStyle(fontSize: 12),),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.start,
                      controller: newPasswordController,
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
                      onChanged: (string)async{
                        passwordContainsSpecial();
                        setState(() {

                        });
                      },
                    ),
                  ),
                ],
              ),
              Text(
                  AppLocalizations.of(context)!.atLeast8Chars,
                  style: TextStyle(
                      fontSize: 12,
                      color: newPasswordController.text == "" ? Colors.grey[500] : newPasswordController.text.length >= 8 ? Colors.green : Colors.red
                  )
              ),
              Text(
                  AppLocalizations.of(context)!.mustContainSymbol,
                  style: TextStyle(
                      fontSize: 12,
                      color: newPasswordController.text == "" ? Colors.grey[500] : passwordContainsSpecial() ? Colors.green : Colors.red
                  )
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
                      updatePassword();
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 50),side: const BorderSide(color: Color(0xff0099f0))),
                    child: Text(AppLocalizations.of(context)!.changePassword,)
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  bool passwordContainsSpecial() {
    return RegExp(r'^(?=.*?[!@#\$&*~])').hasMatch(newPasswordController.text);
  }

  updatePassword() async{

    final token = tbClient.getJwtToken();

    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    try{
      await dio.post(
          "https://dashboard.livair.io/api/auth/changePassword",
        data: jsonEncode(
            {
              "currentPassword": oldPasswordController.text,
              "newPassword": newPasswordController.text
            }
        )
      );
      setState(() {
        currentIndex = 2;
        showAppBar = true;
        appBarTitle = AppLocalizations.of(context)!.generalSettingsT;
      });
    }catch(e){
      logger.e(e);
    }
  }

  showProfilePageScreen() {
    return Column(
      children: [
        const SizedBox(height: 25,),
        Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                height: 100.0,
                decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(1)),color: Colors.white,border: Border(bottom: BorderSide(color: Color(0xffb0bec5)))),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text("${AppLocalizations.of(context)!.helloT} ${name.toUpperCase().split(" ")[0]}!",style: const TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w400),),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                              onPressed: () async{
                                const storage = FlutterSecureStorage();
                                await storage.delete(key: 'email');
                                await storage.delete(key: 'password');
                                if(await storage.containsKey(key: "autoSignIn")){
                                  await storage.delete(key: "autoSignIn");
                                }
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(minimumSize: const Size(80, 50),side: const BorderSide(color: Color(0xff0099f0))),
                              child: Text(AppLocalizations.of(context)!.logout,style: const TextStyle(color: Color(0xff0099f0),fontSize: 14,fontWeight: FontWeight.w500),)
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: ()async{
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
                      currentIndex = 1;
                      showAppBar = true;
                      appBarTitle = AppLocalizations.of(context)!.personalDataT;
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
                            const ImageIcon(AssetImage('lib/images/user.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.personalData,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
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
                    setState((){
                      currentIndex = 2;
                      showAppBar = true;
                      appBarTitle = AppLocalizations.of(context)!.generalSettingsT;
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
                            const ImageIcon(AssetImage('lib/images/settings.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.generalSettings,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
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
                    setState((){
                      currentIndex = 5;
                      showAppBar = true;
                      appBarTitle = AppLocalizations.of(context)!.manageUsersT;
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
                            const ImageIcon(AssetImage('lib/images/usersS.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.manageUsers,style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70,),
            Column(
              children: [
                GestureDetector(
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
                    setState((){
                      currentIndex = 10;
                      showAppBar = true;
                      appBarTitle = AppLocalizations.of(context)!.imprintT;
                    });
                  },
                  child: Container(
                    height: 50,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(width: 1,color: Color(0xffb0bec5)),
                        top: BorderSide(width: 1,color: Color(0xffb0bec5)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 16,),
                            const ImageIcon(AssetImage('lib/images/termsOfService.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.imprint,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    setState(() {
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
                            const ImageIcon(AssetImage('lib/images/termsOfService.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.termsOfService,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
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
                    setState((){
                      currentIndex = 9;
                      showAppBar = true;
                      appBarTitle = AppLocalizations.of(context)!.privacyPolicyyT;
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
                            const ImageIcon(AssetImage('lib/images/privacyPolicy.png')),
                            const SizedBox(width: 14,),
                            Text(AppLocalizations.of(context)!.privacyPolicy,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  showPolicyScreen(){
    return PolicyText();
  }

  showImprintScreen(){
    return ImprintText();
  }

  showPersonalDataScreen() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Column(
              children: [
                const SizedBox(height: 10,),
                const Row(
                  children: [
                    Text("Name")
                  ],
                ),
                const SizedBox(height: 5,),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.start,
                        controller: nameController,
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
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.email)
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.start,
                        controller: emailController,
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: ()async{
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
                            postProfileData();
                          },
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50),side: const BorderSide(width: 2,color: Color(0xff0099f0))),
                          child: Text(AppLocalizations.of(context)!.updatePersData, style: const TextStyle(color: Color(0xff0099f0)),)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: ()async{
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
                              currentIndex = 8;
                              oldPasswordController.text = "";
                              newPasswordController.text = "";
                              appBarTitle = AppLocalizations.of(context)!.changePasswordT;
                              showAppBar = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50),side: const BorderSide(width: 2,color: Color(0xff0099f0))),
                          child: Text(AppLocalizations.of(context)!.changePassword, style: const TextStyle(color: Color(0xff0099f0)),)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: ()async{
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
                              currentIndex = 11;
                              appBarTitle = AppLocalizations.of(context)!.deleteAccountT;
                              showAppBar = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white,minimumSize: const Size(100, 50),side: const BorderSide(width: 2,color: Color(0xff0099f0))),
                          child: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: Color(0xff0099f0)),)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  deleteAccountScreen(){
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.helpUsBecomeBetter, style: const TextStyle(fontSize: 12),),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      maxLines: 5,
                      textAlign: TextAlign.start,
                      controller: deleteReasonController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.tellUsReason,
                        hintTextDirection: TextDirection.ltr,
                        hintStyle: const TextStyle(color: Color(0xff90A4AE)),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.deleteAccountM, style: const TextStyle(fontSize: 12),),
              const SizedBox(height: 20,),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: () async{
                          if(await canDeleteAccount()){
                            final token = tbClient.getJwtToken();
                            dio.options.headers['content-Type'] = 'application/json';
                            dio.options.headers['Accept'] = "application/json, text/plain, */*";
                            dio.options.headers['Authorization'] = "Bearer $token";
                            try{
                              await dio.delete('https://dashboard.livair.io/api/livAir/deleteAccount');
                            }on DioError catch(e){
                              return;
                            }
                            const storage = FlutterSecureStorage();
                            await storage.delete(key: 'email');
                            await storage.delete(key: 'password');
                            if(await storage.containsKey(key: "autoSignIn")){
                              await storage.delete(key: "autoSignIn");
                            }
                            Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099F0),minimumSize: const Size(80, 50),side: const BorderSide(color: Color(0xff0099F0))),
                        child: Text(AppLocalizations.of(context)!.deleteAccount,style: const TextStyle(color: Colors.white),)
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

   Future<bool> canDeleteAccount() async{
    final token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json, text/plain, */*";
    dio.options.headers['Authorization'] = "Bearer $token";
    var result;
    try{
      result = await dio.get('https://dashboard.livair.io/api/livAir/canDeleteAccount');
    }on DioError catch(e){
    }
    if(!result.data){
      setState(() {
        currentIndex = 1;
        appBarTitle = AppLocalizations.of(context)!.personalDataT;
        showAppBar = true;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      AlertDialog alert = AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.stillGotDevicesM),
            const SizedBox(height: 30,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: Color(0xff0099F0),minimumSize: const Size(80, 50),side: const BorderSide(color: Color(0xff0099F0))),
                      child: Text(AppLocalizations.of(context)!.contin,style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ],
        ),
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
      return false;
    }
    return true;
  }

  showGeneralSettingsScreen(){
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            setState(() {
              currentIndex = 3;
              showAppBar = true;
              appBarTitle = AppLocalizations.of(context)!.languageT;
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20,),
                    Text(AppLocalizations.of(context)!.language,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.localeName.toUpperCase(),style: const TextStyle(fontSize: 16,color: Color(0xff78909C)),),
                    const ImageIcon(AssetImage('lib/images/ListButton_Triangle.png')),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: (){
            setState(() {
              currentIndex = 4;
              showAppBar = true;
              appBarTitle = AppLocalizations.of(context)!.radonUnitT;
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20,),
                    Text(AppLocalizations.of(context)!.radonUnit,style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Text(unit!,style: const TextStyle(fontSize: 16,color: Color(0xff78909C)),),
                    const ImageIcon(AssetImage('lib/images/ListButton_Triangle.png')),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  showLanguageScreen(){
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final token = tbClient.getJwtToken();
            dio.options.headers['content-Type'] = 'application/json';
            dio.options.headers['Accept'] = "application/json, text/plain, */*";
            dio.options.headers['Authorization'] = "Bearer $token";
            dio.post('https://dashboard.livair.io/api/livAir/language/english');
            setState(() {
              MVP.of(context)!.setLocale(const Locale.fromSubtags(languageCode: 'en'));
              currentIndex = 0;
              showAppBar = false;
              appBarTitle = "";
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    SizedBox(width: 16,),
                    Text("English",style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Icon(language != "english" ? Icons.circle : Icons.circle_outlined,color: const Color(0xff0099f0),),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: (){
            final token = tbClient.getJwtToken();
            dio.options.headers['content-Type'] = 'application/json';
            dio.options.headers['Accept'] = "application/json, text/plain, */*";
            dio.options.headers['Authorization'] = "Bearer $token";
            dio.post('https://dashboard.livair.io/api/livAir/language/german');
            setState(() {
              MVP.of(context)!.setLocale(const Locale.fromSubtags(languageCode: 'de'));
              currentIndex = 0;
              showAppBar = false;
              appBarTitle = "";
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    SizedBox(width: 16,),

                    Text("Deutsch",style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Icon(language == "english" ? Icons.circle : Icons.circle_outlined,color: const Color(0xff0099f0),),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  showUnitScreen(){
    return Column(
      children: [
        GestureDetector(
          onTap: (){
            final token = tbClient.getJwtToken();
            dio.options.headers['content-Type'] = 'application/json';
            dio.options.headers['Accept'] = "application/json, text/plain, */*";
            dio.options.headers['Authorization'] = "Bearer $token";
            dio.post('https://dashboard.livair.io/api/livAir/units/BqM3');
            setState(() {
              storage.write(key: 'unit', value: "Bq/m³");
              currentIndex = 0;
              showAppBar = false;
              appBarTitle = "";
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    SizedBox(width: 16,),
                    Text("Becquerel (Bq/m³)",style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Icon(unit == "Bq/m³" ? Icons.circle : Icons.circle_outlined,color: const Color(0xff0099f0),),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: (){
            final token = tbClient.getJwtToken();
            dio.options.headers['content-Type'] = 'application/json';
            dio.options.headers['Accept'] = "application/json, text/plain, */*";
            dio.options.headers['Authorization'] = "Bearer $token";
            dio.post('https://dashboard.livair.io/api/livAir/units/pCiL');
            setState(() {
              storage.write(key: 'unit', value: "pCi/L");
              currentIndex = 0;
              showAppBar = false;
              appBarTitle = "";
            });
          },
          child: Container(
            height: 50.0,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(width: 1,color: Color(0xffb0bec5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  children: [
                    SizedBox(width: 16,),

                    Text("Picocuries (pCi/L)",style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w400,), textAlign: TextAlign.center),
                  ],
                ),
                Row(
                  children: [
                    Icon(unit == "pCi/L" ? Icons.circle : Icons.circle_outlined,color: const Color(0xff0099f0),),
                    const SizedBox(width: 22,)
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  shareDeviceScreen(){
    return FutureBuilder(
      future: getViewers(),
      builder: (context,snapshot) {
        return viewerData.isEmpty ?
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ImageIcon(AssetImage('lib/images/ListButton_Circle.png'),size: 50,),
                  const SizedBox(height: 15,),
                  Text(AppLocalizations.of(context)!.noUsersYet),
                  const SizedBox(height: 15,),
                  Text(AppLocalizations.of(context)!.giveSelectedViewingRights,textAlign: TextAlign.center,),
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
                        getAllDevices(6);
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text("${viewerData.elementAt(index).values.elementAt(0)}",style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),),
                                  SizedBox(height: 5,),
                                  Text("${AppLocalizations.of(context)!.canView} ${viewerData.elementAt(index).values.elementAt(1)} device"+ (viewerData.elementAt(index).values.elementAt(1) != 1 ? "s" : "")),
                                ],
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                              ),
                              viewerData.elementAt(index).values.elementAt(3) == true ?
                              SizedBox(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: Color(0xff4fc1f4)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(AppLocalizations.of(context)!.active,style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff4fc1f4)),),
                                    ),
                                  )
                              ) :
                              SizedBox(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: Color(0xffb0bec5)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(AppLocalizations.of(context)!.pendingInvite,style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xffb0bec5))),
                                    ),
                                  )
                              ),
                              PopupMenuButton(
                                  itemBuilder: (context)=>[
                                    PopupMenuItem(
                                      value: 0,
                                      child: Text(AppLocalizations.of(context)!.manageDevices),
                                      onTap: ()async{
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
                                          viewerToManage = viewerData.elementAt(index).values.elementAt(0);
                                          viewerDevicesOld = List.from(viewerData.elementAt(index).values.elementAt(2));
                                          viewerDevicesNew = List.from(viewerData.elementAt(index).values.elementAt(2));
                                          getAllDevices(7);
                                        });
                                      },
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Text(AppLocalizations.of(context)!.remove),
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
                                          devicesToUnshare = viewerData.elementAt(index).values.elementAt(2);
                                          emailToRemove = viewerData.elementAt(index).values.elementAt(0);
                                          removeViewer();
                                        });
                                      },
                                    ),
                                  ]
                              ),
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
        );
      }
    );
  }

  addViewerScreen(){
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog3),
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog2)
                      ]
                  ),
                ),
                const SizedBox(height: 36,),
                Text(AppLocalizations.of(context)!.inviteViewer),
                const SizedBox(height: 36,),
                TextField(
                  textAlign: TextAlign.start,
                  controller: emailController2,
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
            Text(AppLocalizations.of(context)!.yourDevices),
            Expanded(
              child: ListView.separated(
                  itemBuilder: (BuildContext context, int index){
                    return Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(labels.elementAt(index)),
                          IconButton(
                              onPressed: (){
                                setState(() {
                                  if(devicesToShare.contains(deviceIds.elementAt(index))){
                                    devicesToShare.remove(deviceIds.elementAt(index));
                                  }else{
                                    devicesToShare.add(deviceIds.elementAt(index));
                                  }
                                });
                              },
                              icon: devicesToShare.contains(deviceIds.elementAt(index)) ? Icon(Icons.circle) : Icon(Icons.circle_outlined),
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 1),
                  itemCount: deviceIds.length
              ),
            ),
            const SizedBox(height: 36,),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: ()async{
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
                        isValidEmail2() == true ? sendShareInvite2() : null;
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.invite, style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),
          ]
      ),
    );
  }

  manageViewerScreen(){
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog3),
                        TextSpan(text: AppLocalizations.of(context)!.addViewerDialog2)
                      ]
                  ),
                ),
                const SizedBox(height: 36,),
                Text(AppLocalizations.of(context)!.viewerEmail),
                Text(viewerToManage),
              ],
            ),
            const SizedBox(height: 36,),
            Text(AppLocalizations.of(context)!.yourDevices),
            Expanded(
              child: ListView.separated(
                  itemBuilder: (BuildContext context, int index){
                    return Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(labels.elementAt(index)),
                          IconButton(
                            onPressed: (){
                              setState(() {
                                if(viewerDevicesNew.contains(deviceIds.elementAt(index))){
                                  viewerDevicesNew.remove(deviceIds.elementAt(index));
                                }else{
                                  viewerDevicesNew.add(deviceIds.elementAt(index));
                                }
                              });
                            },
                            icon: viewerDevicesNew.contains(deviceIds.elementAt(index)) ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                          )
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 1),
                  itemCount: deviceIds.length
              ),
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
                        List<dynamic> changes = viewerDevicesOld.where((item) => !viewerDevicesNew.contains(item)).toList();
                        devicesToShare = changes.where((item) => viewerDevicesNew.contains(item)).toList();
                        devicesToUnshare = changes.where((item) => viewerDevicesOld.contains(item)).toList();
                        emailToRemove = viewerToManage;
                        if(isValidEmail2()){
                          if(devicesToShare.isNotEmpty) sendShareInvite3();
                          removeViewer();
                        }
                        setState(() {
                          currentIndex = 5;
                          appBarTitle = AppLocalizations.of(context)!.manageUsersT;
                          showAppBar = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xff0099f0),minimumSize: const Size(100, 50)),
                      child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),
          ]
      ),
    );
  }

  sendShareInvite() async {
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
                "deviceIds": devicesToShare,
                "email": emailController.text
              }
          )
      );
      devicesToShare = [];
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        currentIndex = 5;
        appBarTitle = AppLocalizations.of(context)!.manageUsersT;
        showAppBar = true;
      });
    }on DioError catch (e){
      logger.e(e.message);
    }
  }

  sendShareInvite2() async {
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
                "deviceIds": devicesToShare,
                "email": emailController2.text
              }
          )
      );
      devicesToShare = [];
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        currentIndex = 5;
        appBarTitle = AppLocalizations.of(context)!.manageUsersT;
        showAppBar = true;
      });
    }on DioError catch (e){
      logger.e(e.message);
    }
  }

  sendShareInvite3() async {
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
                "deviceIds": devicesToShare,
                "email": emailToRemove
              }
          )
      );
      devicesToShare = [];
      emailToRemove = "";
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        currentIndex = 5;
        appBarTitle = AppLocalizations.of(context)!.manageUsersT;
        showAppBar = true;
      });
    }on DioError catch (e){
      logger.e(e.message);
    }
  }

  getViewers() async {
    var token = tbClient.getJwtToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";
    var response;
    try{
      response = await dio. get(
        'https://dashboard.livair.io/api/livAir/viewers/',
      );
      viewerData = response.data;
    }catch(e){
      print(e);
    }
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
            "deviceIds": devicesToUnshare,
            "email": emailToRemove
          })
      );
    }on DioError catch(e){
      print(e.response);
    }
    devicesToUnshare = [];
    emailToRemove = "";
    setState(() {

    });
  }

  getAllDevices(int index){
    deviceIds = [];
    labels = [];
    devicesToShare = [];

    WebSocketChannel channel;
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
                      "latestValues": []
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
        }
        channel.sink.close();
        setState(() {
          currentIndex = index;
          appBarTitle = index == 6 ? AppLocalizations.of(context)!.addUserT : AppLocalizations.of(context)!.manageUsersT;
          showAppBar = true;
        });
      });
    }catch(e){

    }
  }

  bool isValidEmail2() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(emailController2.text);
  }

  Widget setPage(int index) {
    switch (index) {
      case 0: return showProfilePageScreen();
      case 1: return showPersonalDataScreen();
      case 2: return showGeneralSettingsScreen();
      case 3: return showLanguageScreen();
      case 4: return showUnitScreen();
      case 5: return shareDeviceScreen();
      case 6: return addViewerScreen();
      case 7: return manageViewerScreen();
      case 8: return showPasswordScreen();
      case 9: return showPolicyScreen();
      case 10: return showImprintScreen();
      case 11: return deleteAccountScreen();
      default:
        return showProfilePageScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getProfileData(),
      builder: (context,snapshot) {
        return PopScope(
          canPop: false,
          child: Scaffold(
              appBar: showAppBar ? AppBar(
                elevation: 0,
                automaticallyImplyLeading: false,
                iconTheme: const IconThemeData(
                  color: Colors.black,
                ),
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: (){
                        if(currentIndex == 0){
                          Navigator.pop(context);
                        }else{
                          setState(() {
                            currentIndex = 0;
                            showAppBar = false;
                            appBarTitle = "";
                          });
                        }
                      },
                    ),
                    Text(appBarTitle,style: const TextStyle( fontSize: 20,fontWeight: FontWeight.w400),),
                  ],
                ),
                actions: currentIndex == 5 ? [
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
                        getAllDevices(6);
                      },
                      icon: const Icon(MaterialSymbols.add)
                  ),
                ]: [],
              ) : null,
              body: Center(
                child: setPage(currentIndex),
              )
          ),
        );
      }
    );
  }
  
  
}