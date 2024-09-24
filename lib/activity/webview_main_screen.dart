import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnup/utils/allurls.dart';
import 'package:url_launcher/url_launcher.dart';


class Webview_Main extends StatefulWidget {
  String lat;
  String lng;
  String fcm;
  Webview_Main({Key? key,required this.lat,required this.lng,required this.fcm}) : super(key: key);

  @override
  _Webview_MainState createState() => _Webview_MainState();
}

class _Webview_MainState extends State<Webview_Main> {
  /*late WebViewXController webviewController;
  final initialContent = AllUrls.Main_Webview_URL+"init.php";*/

  // final initialContent =AllUrls.Main_Webview_URL+"splash.php";


  String lat = "";
  String long = "";
  late SharedPreferences prefs;

  String initialContent = "";
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialContent = AllUrls.Main_Webview_URL+"init.php?lat="+widget.lat+"&lon="+widget.lng+"&device="+widget.fcm;
    print("WebViewUrl>>>"+initialContent);

    getSharedPreferences();

    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              androidId: 1,
              iosId: "1",
              title: "Special",
              action: () async {
                // await webViewController?.clearFocus();
              })
        ],
        options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
        },
        onHideContextMenu: () {
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.androidId
              : contextMenuItemClicked.iosId;

        });

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );


  }
  prefences()async{
    //   _getGeoLocationPosition();
   // locationfunction();
    lat = prefs.getString("lat").toString();
    long = prefs.getString("long").toString();
    String fcmtoken = prefs.getString("fcmtoken").toString();
    // initialContent = AllUrls.Main_Webview_URL+"init.php?lat="+lat+"&lon="+long+"&device="+fcmtoken;
    setState(() {

    });

  }
  getSharedPreferences () async
  {
    prefs = await SharedPreferences.getInstance();
    prefences();
  }

  @override
  void dispose() {
    // webviewController.dispose();
    super.dispose();
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
              "assets/images/img_splash_bg.png",
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            Container(
              color: Colors.black,
              child:Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    // contextMenu: contextMenu,
                    initialUrlRequest: URLRequest(url: Uri.parse(initialContent)),
                    initialUserScripts: UnmodifiableListView<UserScript>([]),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                        print("url >>>>>>"+url.toString());
                      });
                    },
                    androidOnPermissionRequest: (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;

                      if (![
                        "http",
                        "https",
                        "file",
                        "chrome",
                        "data",
                        "javascript",
                        "about"
                      ].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          await launch(
                            url,
                          );
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ), progress < 1.0 ? LinearProgressIndicator(value: progress) : Container(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  /* Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }*/

  locationfunction()async{
    Position position = await Geolocator.getCurrentPosition();
    lat = position.latitude.toString();
    long = position.longitude.toString();
    disscusionDetail(context, lat, long, prefs.getString("fcmtoken").toString());
  }

  Future<void> disscusionDetail(BuildContext context,String lat,String lng,String fcmtoken) async {

    HttpWithMiddleware http = HttpWithMiddleware.build(middlewares: [
      HttpLogger(logLevel: LogLevel.BODY),
    ]);

    var response = await http.get(Uri.parse(AllUrls.Main_Webview_URL+"mobgeo.php?lat="+lat+"&lon="+lng+"&device="+fcmtoken));
    // var response = await http.get(Uri.parse(AllUrls.Main_Webview_URL+"mobgeo.php?lat="+lat+"&lon="+lng+"&cfm="+fcmtoken));
    return;
  }
}
