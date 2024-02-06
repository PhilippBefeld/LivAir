import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:mvp/pages/root_page.dart';
import 'package:thingsboard_pe_client/thingsboard_client.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpPage extends StatefulWidget{

  final ThingsboardClient tbClient;

  SignUpPage({super.key, required this.tbClient});

  @override
  State<SignUpPage> createState() => SignUpPageState(tbClient);

}

class SignUpPageState extends State<SignUpPage>{

  final ThingsboardClient tbClient;
  final Dio dio = Dio();
  final Logger logger = Logger();
  SignUpPageState(this.tbClient);
  final storage = FlutterSecureStorage();

  TextEditingController nameController = TextEditingController();
  TextEditingController surNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController confirmationCodeController = TextEditingController();

  bool agreedToPolicy = false;
  bool agreedToNews = false;
  bool emailCorrect = false;
  bool passwordCorrect = false;



  googleSignUp()async{
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
    } catch (error) {
      print(error);
      return;
    }
  }

  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(emailController.text);
  }
  
  bool passwordContainsSpecial() {
    return RegExp(r'^(?=.*?[!@#\$&*~])').hasMatch(passwordController.text);
  }

  sendConfirmationCode() async{
    try{
      var response = await dio.post(
        'https://dashboard.livair.io/api/livAir/verifyCode',
        data: jsonEncode(
            {
              "email": emailController.text,
              "verificationCode": confirmationCodeController.text
            }
        ),
      );
      if(response.statusCode == 200){
        try{
          await tbClient.login(
              LoginRequest(
                  emailController.text,
                  passwordController.text
              )
          );
          await storage.write(key: 'password', value: passwordController.text);
          await storage.write(key: 'email', value: emailController.text);
          await storage.write(key: 'unit', value: 'Bq/m³');
          Navigator.pop(context);
          Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => DestinationView(tbClient: tbClient)
              )
          );
        }catch(e){
          Navigator.pop(context);
          logger.e(e);
        }
      }else{
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.wrongCode
        );
      }
    }on DioError catch(e){
    print(e.response);
    print(e.message);
    }
  }

  signUp() async{
    if(!isValidEmail() || !passwordContainsSpecial() || passwordController.text.length < 8 || !(passwordController.text == confirmPasswordController.text)){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.checkData
      );
      return;
    }
    if(!agreedToPolicy){
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.agreeToPolicies
      );
      return;
    }
    String token = '';
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers['Accept'] = "application/json, text/plain, */*";

    try{
      var response = await dio.get(
          'https://dashboard.livair.io/dashboard',

      );
      response = await dio.post(
        'https://dashboard.livair.io/api/auth/login/public',
        data: jsonEncode(
          {
            "publicId": "ae5668c0-8d2c-11ee-908b-7329b1812c67"
          }
        )
      );
      token = response.data['token'];
      dio.options.headers['Authorization'] = "Bearer $token";
    }on DioError catch(e){
      logger.e(e.response);
    }

    try{
      dio.post(
        'https://dashboard.livair.io/api/livAir/createUser',
        data: jsonEncode(
          {
            "name": "${nameController.text} ${surNameController.text}",
            "email": emailController.text,
            "password": passwordController.text,
            "receiveUpdates": agreedToNews,
            "language": "ENGLISH"
          }
        ),
      );
    }on DioError catch(e){
      logger.e(e.response);
    }

    openDialog() => showDialog(
        context: context,
        builder: (context) => Builder(
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.enterVerificationCode),
              content: Column(
                children: [
                  MyTextField(
                    controller: confirmationCodeController,
                    hintText: "",
                    obscureText: false,
                    onChanged: null,
                    initialValue: null,
                    inputType: TextInputType.number,
                  ),
                  const SizedBox(height: 30,),
                  MyButton(
                    padding: const EdgeInsets.all(10),
                    heigth: 60,
                    textInhalt: AppLocalizations.of(context)!.confirm,
                    onTap: sendConfirmationCode,
                  ),
                  MyButton(
                    padding: const EdgeInsets.all(10),
                    heigth: 60,
                    textInhalt: AppLocalizations.of(context)!.newVerificationCode,
                    onTap: resendVerificationCode,
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
    return Builder(
        builder: (context){
          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22,0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10,),
                        Row(
                          children: [
                            Text(AppLocalizations.of(context)!.signUp,style: const TextStyle(fontFamily: "Inter",fontSize: 20.0,fontWeight: FontWeight.w600,),),
                          ],
                        ),
                        const SizedBox(height: 30,),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5.0,0,5,0),
                          child: GestureDetector(
                              onTap: googleSignUp,
                              child: const Image(image: AssetImage('lib/images/SignInWithGoogle.png'),color: null,)
                          ),
                        ),
                        const SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5.0,0,5,0),
                          child: GestureDetector(
                              onTap: null,
                              child: const Image(image: AssetImage('lib/images/SignInWithFacebook.png'),color: null,)
                          ),
                        ),
                        const SizedBox(height: 50,),
                        MyTextField(
                          onChanged: null,
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!.yourName,
                          obscureText: false,
                          initialValue: nameController.text,
                          label: AppLocalizations.of(context)!.name,
                        ),
                        const SizedBox(height: 12,),
                        MyTextField(
                          onChanged: null,
                          controller: surNameController,
                          hintText: AppLocalizations.of(context)!.yourSurname,
                          obscureText: false,
                          initialValue: surNameController.text,
                          label: AppLocalizations.of(context)!.surname,
                        ),
                        const SizedBox(height: 12,),
                        MyTextField(
                          onChanged: null,
                          controller: emailController,
                          hintText: AppLocalizations.of(context)!.yourEmail,
                          obscureText: false,
                          initialValue: emailController.text,
                          label: AppLocalizations.of(context)!.email,
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 26,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emailCorrect ? AppLocalizations.of(context)!.notAValidEmail : "",style: const TextStyle(color: Colors.red),)
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 12,),
                        Text(AppLocalizations.of(context)!.password,style: TextStyle(fontSize: 12),),
                        const SizedBox(height: 5,),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(width: 2,color: Color(0xffeceff1)),
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: AppLocalizations.of(context)!.yourPassword,
                                  hintStyle: TextStyle(color: Color(0xff90a4ae),fontSize: 14),
                                ),
                                onChanged: (string)async{
                                  passwordContainsSpecial();
                                  setState(() {

                                  });
                                },
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5,),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    AppLocalizations.of(context)!.atLeast8Chars,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: passwordController.text == "" ? Colors.grey[500] : passwordController.text.length >= 8 ? Colors.green : Colors.red
                                  )
                                ),
                                Text(
                                    AppLocalizations.of(context)!.mustContainSymbol,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: passwordController.text == "" ? Colors.grey[500] : passwordContainsSpecial() ? Colors.green : Colors.red
                                  )
                                ),
                              ],
                            )
                            ],
                        ),
                        const SizedBox(height: 12,),
                        MyTextField(
                          onChanged: null,
                          controller: confirmPasswordController,
                          hintText: AppLocalizations.of(context)!.confirmYourPassword,
                          obscureText: true,
                          initialValue: confirmPasswordController.text,
                          label: AppLocalizations.of(context)!.confirmPassword,
                        ),
                        ListTileTheme(
                          horizontalTitleGap: 0,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(AppLocalizations.of(context)!.agreeToTerms,style: const TextStyle(fontSize: 14),textWidthBasis: TextWidthBasis.parent,),
                            value: agreedToPolicy,
                            onChanged: (bool? value){
                              setState((){
                                agreedToPolicy = value!;
                              });
                            },
                          ),
                        ),
                        ListTileTheme(
                          horizontalTitleGap: 0,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(AppLocalizations.of(context)!.agreeToUpdates,style: const TextStyle(fontSize: 14),textWidthBasis: TextWidthBasis.parent,),
                            value: agreedToNews,
                            onChanged: (bool? value){
                              setState((){
                                agreedToNews = value!;
                              });
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: signUp,
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(width: 2,color: Color(0xff0099f0)),
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xff0099f0),
                                    minimumSize: const Size(0, 45)
                                ),
                                child: Text(AppLocalizations.of(context)!.createAccount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50,),
                        Row(
                          children: [
                            Text("*${AppLocalizations.of(context)!.requiredInformation}",style: const TextStyle(fontSize: 12,color: Color(0xff546e7a)),)
                          ],
                        ),
                        const SizedBox(height: 50,),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}