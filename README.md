# Push notification plugins for Flutter

---

A Flutter plugins to use for Push notification

With this plugin, your Flutter app can receive and process push notifications as well as data messages on Android and iOS.
Note: This plugin is still under development, and some APIs might not be available yet. Feedback and Pull Requests are most welcome!

## Usage

---

To use this plugin, add below to pubspec.yaml

```yaml
push_notification:
  git:
    url: https://github.com/BlueChilli/push_notification_plugin.git
```

## Getting Started

Check out the `example` directory for a sample app using this plugin.

### Android Integration

To integrate your plugin into the Android part of your app, follow these steps:

1. Using the [Firebase Console](https://console.firebase.google.com/) add an Android app to your project: Follow the assistant, download the generated `google-services.json` file and place it inside `android/app`. Next, modify the `android/build.gradle` file and the `android/app/build.gradle` file to add the Google services plugin as described by the Firebase assistant.

1. (optional, but recommended) If want to be notified in your app (via `onResume` and `onLaunch`, see below) when the user clicks on a notification in the system tray include the following `intent-filter` within the `<activity>` tag of your `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
    <action android:name="FLUTTER_NOTIFICATION_CLICK" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

2. if you want to change icon for notification message, add below to your `android/app/src/main/AndroidManifest.xml`

```xml
 <meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/ic_launcher_round" />
```

### iOS Integration

To integrate your plugin into the iOS part of your app, follow these steps:

1. In Xcode, select `Runner` in the Project Navigator. In the Capabilities Tab turn on `Push Notifications`.

### Dart/Flutter Integration

From your Dart code, you need to import the plugin and instantiate it:

```dart
import 'package:push_notification/push_notification.dart';

final PushNotification _notificationPlugin = PushNotification();
```

Next, you should probably request permissions for receiving Push Notifications. For this, call `_notificationPlugin.requestNotificationPermissions()`. This will bring up a permissions dialog for the user to confirm on iOS. It's a no-op on Android. Last, but not least, register `onMessage`, `onResume`, and `onLaunch` callbacks via `_notificationPlugin.configure()` to listen for incoming messages (see table below for more information).

## Load Token

You can get the push notification token using below method

```dart
 var token = await _notificationPlugin.getToken();
```

## Refreshing Token

You can add listener to the event listener to get push notification token

```dart
_subscription = _notificationPlugin.onTokenRefresh.listen((token) {
      _tokenRecievedSubject.add(token);
    });
```

## Receiving Messages

Messages are sent to your Flutter app via the `onMessage`, `onLaunch`, and `onResume` callbacks that you configured with the plugin during setup. Here is how different message types are delivered on the supported platforms:

|                             | App in Foreground | App in Background                                                                                                                                                   | App Terminated                                                                                                                                                      |
| --------------------------: | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Notification on Android** | `onMessage`       | Notification is delivered to system tray. When the user clicks on it to open app `onResume` fires if `click_action: FLUTTER_NOTIFICATION_CLICK` is set (see below). | Notification is delivered to system tray. When the user clicks on it to open app `onLaunch` fires if `click_action: FLUTTER_NOTIFICATION_CLICK` is set (see below). |
|     **Notification on iOS** | `onMessage`       | Notification is delivered to system tray. When the user clicks on it to open app `onResume` fires.                                                                  | Notification is delivered to system tray. When the user clicks on it to open app `onLaunch` fires.                                                                  |
| **Data Message on Android** | `onMessage`       | `onMessage` while app stays in the background.                                                                                                                      | _not supported by plugin, message is lost_                                                                                                                          |
|     **Data Message on iOS** | `onMessage`       | Message is stored by FCM and delivered to app via `onMessage` when the app is brought back to foreground.                                                           | Message is stored by FCM and delivered to app via `onMessage` when the app is brought back to foreground.                                                           |

Additional reading: Firebase's [About FCM Messages](https://firebase.google.com/docs/cloud-messaging/concept-options).

## Sending Messages

Refer to the [Firebase documentation](https://firebase.google.com/docs/cloud-messaging/) about FCM for all the details about sending messages to your app. When sending a notification message to an Android device, you need to make sure to set the `click_action` property of the message to `FLUTTER_NOTIFICATION_CLICK`. Otherwise the plugin will be unable to deliver the notification to your app when the users clicks on it in the system tray.

For testing purposes, the simplest way to send a notification is via the [Firebase Console](https://firebase.google.com/docs/cloud-messaging/send-with-console). Make sure to include `click_action: FLUTTER_NOTIFICATION_CLICK` as a "Custom data" key-value-pair (under "Advanced options") when targeting an Android device. The Firebase Console does not support sending data messages.

Alternatively, a notification or data message can be sent from a terminal:

```shell
DATA='{"notification": {"body": "this is a body","title": "this is a title"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "<FCM TOKEN>"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=<FCM SERVER KEY>"
```

Remove the `notification` property in `DATA` to send a data message.
