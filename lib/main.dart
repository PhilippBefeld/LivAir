
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mvp/pages/sign_in_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/l10n.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MVP()); // Wrap your app
}

class MVP extends StatefulWidget {

  @override
  MVPState createState() => MVPState();

  static MVPState? of(BuildContext context) => context.findAncestorStateOfType<MVPState>();
}


class MVPState extends State<MVP>{

  Locale _locale = const Locale('en');



  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }


  @override
  Widget build(BuildContext context){
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(// navigation bar color
      statusBarColor: Colors.white, // status bar color
    ));
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: L10n.all,
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}

