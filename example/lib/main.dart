import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:push_notification/push_notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String channelId = "com.bluechilli.pushnotification.plugin.channel";
const String channelName = "PushNotificationPlugin";
const String channelDesc = "PushNotificationPlugin";

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _token = 'Unknown';
  bool _isGranted = false;

  PushNotification notification = PushNotification();
  StreamSubscription<String> _tokenSubscripition;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tokenSubscripition = notification.onTokenRefresh.listen((token) {
      print(token);
      setState(() {
        _token = token;
      });
    });

    initNotification();
  }

  @override
  void dispose() {
    _tokenSubscripition.cancel();
    _tokenSubscripition = null;

    super.dispose();
  }

  Future _onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  }

  Future<void> initNotification() async {
    bool granted;
    try {
      granted = await notification.requestNotificationPermissions();

      if (granted) {
        var category = IosCategorySettings(
            identifier: "MEETING_INVITATION",
            actions: [
              IosNotificationAction(
                  identifier: "ACCEPT_ACTION",
                  title: "Accept",
                  options: IosNotificationActionOption()),
              IosNotificationAction(
                  identifier: "DECLINE_ACTION",
                  title: "Decline",
                  options: IosNotificationActionOption()),
            ],
            intentIdentifiers: [],
            hiddenPreviewBodyPlaceHolder: "",
            options: IosCategoryOption(customDismissAction: true));

        notification.setCategories([category]);

        notification.configure(onMessage: (data) async {
          print("OnMessage");
          print(data.toString());

          if (Platform.isAndroid) {
            var initializationSettingsAndroid =
                new AndroidInitializationSettings('ic_launcher');
            var initializationSettingsIOS = new IOSInitializationSettings();
            var initializationSettings = new InitializationSettings(
                initializationSettingsAndroid, initializationSettingsIOS);
            flutterLocalNotificationsPlugin.initialize(initializationSettings,
                onSelectNotification: _onSelectNotification);
            var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                channelId, channelName, channelDesc,
                importance: Importance.Max,
                priority: Priority.High,
                ticker: 'ticker');
            var iOSPlatformChannelSpecifics = IOSNotificationDetails();
            var platformChannelSpecifics = NotificationDetails(
                androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
            var notification = data["notification"];
            var payload = data["data"];
            await flutterLocalNotificationsPlugin.show(0, notification["title"],
                notification["body"], platformChannelSpecifics,
                payload: payload["shiftId"]);
          }
        }, onLaunch: (data) {
          print("onLaunch");
          print(data.toString());
        }, onOpen: (data) {
          print("onOpen");
          print(data.toString());
        }, onResume: (data) {
          print("onResume");
          print(data.toString());
        });
      }
    } on PlatformException catch (e) {
      granted = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _isGranted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _isGranted
                  ? Text("Notification has been granted")
                  : Text("Notification has been denied"),
              Container(height: 20.0),
              Text("Push token is $_token")
            ],
          ),
        ),
      ),
    );
  }
}
