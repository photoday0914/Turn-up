import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnup/activity/webview_main_screen.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String fcmtoken="";
  late FirebaseMessaging messaging;

  SharedPreferences? prefs;
  void main() async {
    await Firebase.initializeApp();

    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value){
      print("fcm token>>>>"+value.toString());
      fcmtoken = value.toString();
      prefs?.setString("fcmtoken",fcmtoken);
    });
  }

  void initState() {
    super.initState();
    getSharedPreferences();
    main();
    Timer(
        Duration(seconds: 5),
            () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Webview_Main(lat:prefs!.getString("lat").toString(),lng:prefs!.getString("long").toString(),fcm:fcmtoken))));
  }
  getSharedPreferences () async
  {
    prefs = await SharedPreferences.getInstance();
  }
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQueryData.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
          body: Stack(
            children: [
              Image.asset(

                "assets/images/img_splash_bg_250.png",
                fit: BoxFit.fitHeight,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ],
          )),
    );
  }
}