import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:push_notification/push_notification.dart';

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

  @override
  void initState() {
    super.initState();
    _tokenSubscripition = notification.onTokenRefresh.listen((token) {
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

        notification.configure(onMessage: (data) {
          print("OnMessage");
          print(data.toString());
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
              Text("Push token is ${_token}")
            ],
          ),
        ),
      ),
    );
  }
}
