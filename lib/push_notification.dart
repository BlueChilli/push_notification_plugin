import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);

class PushNotification {
  factory PushNotification() => _instance;

  @visibleForTesting
  PushNotification.private(MethodChannel channel, Platform platform)
      : _channel = channel,
        _platform = platform;

  static final PushNotification _instance = PushNotification.private(
      const MethodChannel('com.bluechilli.plugins/push_notification'),
      const LocalPlatform());

  final MethodChannel _channel;
  final Platform _platform;

  MessageHandler _onMessage;
  MessageHandler _onLaunch;
  MessageHandler _onResume;
  MessageHandler _onOpen;

  String _token;

  /// On iOS, prompts the user for notification permissions the first time
  /// it is called.
  ///
  /// Does nothing on Android.
  Future<bool> requestNotificationPermissions(
      [IosNotificationSettings iosSettings =
          const IosNotificationSettings()]) async {
    if (!_platform.isIOS) {
      return Future<bool>.value(true);
    }

    bool isGranted = await _channel.invokeMethod(
        'requestNotificationPermissions', iosSettings.toMap());

    return isGranted;
  }

  final StreamController<IosNotificationSettings> _iosSettingsStreamController =
      StreamController<IosNotificationSettings>.broadcast();

  /// Stream that fires when the user changes their notification settings.
  ///
  /// Only fires on iOS.
  Stream<IosNotificationSettings> get onIosSettingsRegistered {
    return _iosSettingsStreamController.stream;
  }

  /// Sets up [MessageHandler] for incoming messages.
  void configure({
    MessageHandler onMessage,
    MessageHandler onLaunch,
    MessageHandler onResume,
    MessageHandler onOpen,
  }) {
    _onMessage = onMessage;
    _onLaunch = onLaunch;
    _onResume = onResume;
    _onOpen = onOpen;
    _channel.setMethodCallHandler(_handleMethod);
    _channel.invokeMethod('configure');
  }

  final StreamController<String> _tokenStreamController =
      StreamController<String>.broadcast();

  /// Fires when a new FCM token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  /// Returns the FCM token.
  Future<String> getToken() {
    return _token != null ? Future<String>.value(_token) : onTokenRefresh.first;
  }

  Future<Null> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onToken":
        final String token = call.arguments;
        if (_token != token) {
          _token = token;
          _tokenStreamController.add(_token);
        }
        return null;
      case "onIosSettingsRegistered":
        _iosSettingsStreamController.add(IosNotificationSettings._fromMap(
            call.arguments.cast<String, bool>()));
        return null;
      case "onMessage":
        return _onMessage(call.arguments.cast<String, dynamic>());
      case "onLaunch":
        return _onLaunch(call.arguments.cast<String, dynamic>());
      case "onResume":
        return _onResume(call.arguments.cast<String, dynamic>());
      case "onOpened":
        return _onOpen(call.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecognized JSON message");
    }
  }

  Future<Null> setCategories(List<IosCategorySettings> categories) async {
    if (!_platform.isIOS) {
      return;
    }

    if (categories == null) return;

    var items = categories.map((item) => item.toMap()).toList();
    await _channel.invokeMethod("setupCategories", items);
  }
}

class IosCategorySettings {
  final String identifier;
  final String hiddenPreviewBodyPlaceHolder;
  final IosCategoryOption options;
  final List<IosNotificationAction> actions;
  final List<String> intentIdentifiers;

  IosCategorySettings({
    @required this.identifier,
    this.actions,
    this.intentIdentifiers,
    this.hiddenPreviewBodyPlaceHolder,
    this.options = const IosCategoryOption(),
  });

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'identifier': identifier,
      'actions':
          actions != null ? actions.map((item) => item.toMap()).toList() : [],
      'intentIdentifiers': intentIdentifiers ?? [],
      'hiddenPreviewBodyPlaceHolder': hiddenPreviewBodyPlaceHolder,
      'options': options.toMap()
    };
  }
}

class IosNotificationAction {
  final String identifier;
  final String title;
  final IosNotificationActionOption options;

  IosNotificationAction(
      {@required this.identifier,
      @required this.title,
      this.options = const IosNotificationActionOption()});

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'identifier': identifier,
      'title': title,
      'options': options.toMap()
    };
  }
}

class IosNotificationActionOption {
  final bool authenticationRequired;
  final bool destructive;
  final bool foreground;

  const IosNotificationActionOption(
      {this.authenticationRequired = false,
      this.destructive = false,
      this.foreground = false});

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, bool>{
      'authenticationRequired': authenticationRequired,
      'destructive': destructive,
      'foreground': foreground
    };
  }

  @override
  String toString() => 'IosNotificationActionOption ${toMap()}';
}

class IosCategoryOption {
  final bool customDismissAction;
  final bool allowInCarPlay;
  final bool hiddenPreviewShowTitle;
  final bool hiddenPreviewsShowSubtitle;

  const IosCategoryOption(
      {this.customDismissAction = false,
      this.allowInCarPlay = false,
      this.hiddenPreviewShowTitle = false,
      this.hiddenPreviewsShowSubtitle = false});

  const IosCategoryOption.all()
      : customDismissAction = true,
        allowInCarPlay = true,
        hiddenPreviewShowTitle = true,
        hiddenPreviewsShowSubtitle = true;

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, bool>{
      'customDismissAction': customDismissAction,
      'allowInCarPlay': allowInCarPlay,
      'hiddenPreviewShowTitle': hiddenPreviewShowTitle,
      'hiddenPreviewsShowSubtitle': hiddenPreviewsShowSubtitle
    };
  }

  @override
  String toString() => 'IosCategoryOption ${toMap()}';
}

class IosNotificationSettings {
  const IosNotificationSettings({
    this.sound = true,
    this.alert = true,
    this.badge = true,
  });

  IosNotificationSettings._fromMap(Map<String, bool> settings)
      : sound = settings['sound'],
        alert = settings['alert'],
        badge = settings['badge'];

  final bool sound;
  final bool alert;
  final bool badge;

  @visibleForTesting
  Map<String, dynamic> toMap() {
    return <String, bool>{'sound': sound, 'alert': alert, 'badge': badge};
  }

  @override
  String toString() => 'PushNotificationSettings ${toMap()}';
}
