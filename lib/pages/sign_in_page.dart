import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mvp/components/my_button.dart';
import 'package:mvp/components/my_textfield.dart';
import 'package:mvp/pages/root_page.dart';
import 'package:mvp/pages/sign_up_page.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';




class SignInPage extends StatefulWidget {

  SignInPage({super.key});

  @override
  State<SignInPage> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final Dio dio = Dio();
  final logger = Logger();
  final emailController = TextEditingController();
  final emailResetController = TextEditingController();
  final passwordController = TextEditingController();
  final tbClient = ThingsboardClient('https://dashboard.livair.io');
  final storage = new FlutterSecureStorage();

  String currentScreen = '';

  var lastLoginError = '';
  String? lastEmail;
  String? lastPassword;
  bool emailIsCorrect = false;

  //signIn variables
  bool firstBuild = true;
  bool savePasswordChecked = false;
  bool autoSignIn = false;
  bool credentialsLoaded = false;

  String? googleEmail;

  //emailVerification variables
  final confirmationCodeController = TextEditingController();

  Future<void> onGoBack(dynamic value) async{
    setState(() {
      credentialsLoaded = false;
    });
  }


  void logIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(context: context, builder: (context){
      return const Center(child:CircularProgressIndicator());
    },
    );
    String token = '';
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json, text/plain, */*";
    try {
      try{
        var response = await dio.post(
            'https://dashboard.livair.io/api/auth/login/public',
            data: jsonEncode(
                {
                  "publicId": "dcf75f60-a6ee-11ed-aee2-a1848204f6fb"
                }
            )
        );
        token = response.data['token'];
        dio.options.headers['Authorization'] = "Bearer $token";
        var isVerifiedData = await dio.get('https://dashboard.livair.io/api/livAir/isVerified/${emailController.text}');
        if(isVerifiedData.data == "true"){
          enterConfirmationCode();
          return;
        }
        var languageData = await dio.get('https://dashboard.livair.io/api/livAir/language',options: Options(responseType: ResponseType.plain));
        if(languageData.data != "english"){
          MVP.of(context)!.setLocale(const Locale.fromSubtags(languageCode: 'de'));
        }
        if(!await storage.containsKey(key: 'language')){
          storage.write(key: 'language', value: languageData.data);
        }else{
          if(await storage.read(key: 'language') != languageData.data){
            storage.write(key: 'language', value: languageData.data);
          }
        }
        var unitData = await dio.get('https://dashboard.livair.io/api/livAir/units',options: Options(responseType: ResponseType.plain));
        print(languageData);
        if(!await storage.containsKey(key: 'unit')){
          storage.write(key: 'unit', value: unitData.data);
        }else{
          if(await storage.read(key: 'unit') != unitData.data){
            storage.write(key: 'unit', value: unitData.data);
          }
        }
      }on DioError catch(e){
        logger.e(e);
      }
      await tbClient.login(
          LoginRequest(
              emailController.text,
              passwordController.text
          )
      );
      if(savePasswordChecked){
        await storage.write(key: 'email', value: emailController.text);
        await storage.write(key: 'password', value: passwordController.text);
      }else{
        await storage.delete(key: 'email');
        await storage.delete(key: 'password');
      }
      if(autoSignIn){
        await storage.write(key: "autoSignIn", value: "autoSignIn");
      }
      setState(() {

      });
      Navigator.pop(context);
      Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => DestinationView(tbClient: tbClient),
          )
      ).then(onGoBack);
    } on ThingsboardError catch (e) {

      if(e.message == 'Authentication failed'){
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.loginFailed_badData_toast
        );
      }else{
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.loginFailed_toast
        );
      }

    } on Error catch (e){
      logger.e(e);
    }
  }

  bool isValidEmail(TextEditingController controller) {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(controller.text);
  }

  checkLogInEmail(){
    if(isValidEmail(emailController)){
      emailIsCorrect = true;
    }else{
      emailIsCorrect = false;
    }
  }

  forgotPassword() async{
    final token = tbClient.getJwtToken();

    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json";
    dio.options.headers['Authorization'] = "Bearer $token";

    sendResetRequest(){
      if(!isValidEmail(emailResetController)) {
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.checkEmail_toast
        );
        return;
      }
      try {
        int counter = 0;
        var response = dio.post(
          'https://dashboard.livair.io/api/noauth/livAir/resetPassword/${emailResetController.text}',
        );
        print(response);
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.emailSent_toast
        );
      }catch(e){
        logger.e(e);
      }
    }

    openDialog() => showDialog(
        context: context,
        builder: (context) => Builder(
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.resetPassword),
              content: Column(
                children: [
                  const SizedBox(height: 30,),
                  MyTextField(
                    onChanged: null,
                    controller: emailResetController,
                    hintText: AppLocalizations.of(context)!.emailAddress,
                    obscureText: false,
                    initialValue: null,
                  ),
                  const SizedBox(height: 30,),
                  MyButton(
                    padding: const EdgeInsets.all(10),
                    heigth: 60,
                    textInhalt: AppLocalizations.of(context)!.sendEmail,
                    onTap: sendResetRequest,
                  ),
                ],
              ),
            )
        )
    );
    openDialog();
  }

  getOldCredentials() async {
    if(firstBuild){
      if(await storage.containsKey(key: "email")){
        savePasswordChecked = true;
        emailIsCorrect = true;
        lastEmail = await storage.read(key: 'email');
        lastPassword = await storage.read(key: 'password');
        firstBuild = false;
        emailController.text = (await storage.read(key: 'email'))!;
        passwordController.text = (await storage.read(key: 'password'))!;
      }
      if(await storage.containsKey(key: "autoSignIn")){
        logIn();
        return;
      }
      if(await storage.containsKey(key: "language")){
        if(await storage.read(key: "language") != "english"){
          MVP.of(context)!.setLocale(const Locale.fromSubtags(languageCode: 'de'));
        }
      }
    }
    if(await storage.containsKey(key: "email")== false && credentialsLoaded == false){
      emailController.text = "";
      passwordController.text = "";
      savePasswordChecked = false;
      credentialsLoaded = true;
    }

  }


  googleSignIn()async{
    GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => DestinationView(tbClient: tbClient)
        )
    );
    try {
      var account = await googleSignIn.signIn();
      googleEmail = account!.email;
    } catch (error) {
      print(error);
      return;
    }
  }

  enterConfirmationCode(){
    openDialog() => showDialog(
        context: context,
        builder: (context) => Builder(
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.enterVerificationCode),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Confirmation code"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: confirmationCodeController,
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
                  const SizedBox(height: 5,),
                  Text(AppLocalizations.of(context)!.emailAddress),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                  const SizedBox(height: 30,),
                  Row(
                    children: [
                      Expanded(
                        child:
                        Container(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: (){
                              dio.post('https://dashboard.livair.io/api/livAir/verifyCode',
                                data: jsonEncode(
                                    {
                                      "email": emailController.text,
                                      "verificationCode": confirmationCodeController.text
                                    }
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(width: 0),
                                foregroundColor: const Color(0xff0099F0),
                                backgroundColor: const Color(0xff0099F0),
                                minimumSize: Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.confirm,style: TextStyle(
                                color: Colors.white
                            ),),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15,),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: resendVerificationCode,
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(width: 0),
                                foregroundColor: const Color(0xff0099F0),
                                backgroundColor: const Color(0xff0099F0),
                                minimumSize: Size(60,20)
                            ),
                            child: Text(AppLocalizations.of(context)!.resendVerificationCode,style: TextStyle(
                                color: Colors.white
                            ),),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
        )
    );
    openDialog();

  }

  resendVerificationCode(){
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json, text/plain, */*";
    dio.post('https://dashboard.livair.io/api/livAir/sendVerificationCode/${emailController.text}');
  }

  @override
  Widget build(BuildContext context){
    return FutureBuilder(
        future: getOldCredentials(),
        builder: (context, projectSnap) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22,0),
                  child: Column(
                      children: [
                        const SizedBox(height: 10,),
                        const Image(image: AssetImage('lib/images/LivAir_Light.png'),color: null,),
                        const SizedBox(height: 20,),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context)!.signIn,style: const TextStyle(fontFamily: "Inter",fontSize: 20.0,fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 30,),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5.0,0,5,0),
                          child: GestureDetector(
                            onTap: googleSignIn,
                            child: const Image(image: AssetImage('lib/images/SignInWithGoogle.png'),color: null,)
                          ),
                        ),
                        const SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5,0,5,0),
                          child: GestureDetector(
                              onTap: null,
                              child: const Image(image: AssetImage('lib/images/SignInWithFacebook.png'),color: null,)
                          ),
                        ),
                        const SizedBox(height: 50,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.email,style: const TextStyle(color: Colors.black,fontSize: 12),),
                          ],
                        ),
                        const SizedBox(height: 5,),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
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
                                  hintText: AppLocalizations.of(context)!.emailAddress,
                                  hintStyle: TextStyle(color: Colors.grey[850],fontSize: 14),
                                ),
                                onChanged: (value){
                                  if(checkLogInEmail()){
                                    setState(() {
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.password,style: const TextStyle(color: Colors.black,fontSize: 12),),
                          ],
                        ),
                        const SizedBox(height: 5,),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: AppLocalizations.of(context)!.password,
                                  hintStyle: TextStyle(color: Color(0xff90a4ae),fontSize: 14),
                                ),
                                onChanged: null,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTileTheme(
                                horizontalTitleGap: 0,
                                child: CheckboxListTile(
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.all(0),
                                  title: Text(AppLocalizations.of(context)!.keepSignedIn,style: const TextStyle(fontSize: 14),textWidthBasis: TextWidthBasis.parent,),
                                  value: savePasswordChecked,
                                  onChanged: (bool? value){
                                    setState((){
                                      savePasswordChecked = value!;
                                    });
                                  },
                                ),
                              ),
                            ),

                            TextButton(
                                onPressed: forgotPassword,
                                child: Text(AppLocalizations.of(context)!.forgotPasswordQ,style: const TextStyle(fontSize: 14,decoration: TextDecoration.underline),)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ListTileTheme(
                                horizontalTitleGap: 0,
                                child: CheckboxListTile(
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.all(0),
                                  title: Text(AppLocalizations.of(context)!.autoSignIn,style: const TextStyle(fontSize: 14),textWidthBasis: TextWidthBasis.parent,),
                                  value: autoSignIn,
                                  onChanged: (bool? value){
                                    setState(() {
                                      autoSignIn = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        Text(lastLoginError != '' ? lastLoginError : ''),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: emailIsCorrect  ? logIn : null,
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xff0099F0),
                                  minimumSize: const Size(0, 45)
                                ),
                                child: Text(AppLocalizations.of(context)!.signIn),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context)!.noAccountQ),
                            TextButton(
                                onPressed: (){
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => SignUpPage(tbClient: tbClient)
                                      )
                                  );
                                },
                                child: Text(AppLocalizations.of(context)!.signUp, style: TextStyle(fontSize: 14,decoration: TextDecoration.underline),)
                            )
                          ],
                        )
                      ]
                  ),
                )
              )
            )
          );
      }
    );
  }

}
