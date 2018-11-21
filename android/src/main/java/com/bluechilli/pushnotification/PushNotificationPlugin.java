package com.bluechilli.pushnotification;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v4.content.SharedPreferencesCompat;
import android.util.Log;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.RemoteMessage;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.NewIntentListener;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.HashMap;
import java.util.Map;

import static android.content.Context.MODE_PRIVATE;

/** PushNotificationPlugin */
public class PushNotificationPlugin extends BroadcastReceiver implements MethodCallHandler, NewIntentListener {

  private final Registrar registrar;
  private final MethodChannel channel;

  private static final String CLICK_ACTION_VALUE = "FLUTTER_NOTIFICATION_CLICK";
  private static final String PUSH_NOTIFICATION_PLUGIN_SHARED_PREFERENCE = "com.bluechilli.plugins.pushnotification";
  private static final String PLUGIN_IDENTIFIER = "com.bluechilli.plugins/push_notification";

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), PLUGIN_IDENTIFIER);
    final PushNotificationPlugin plugin = new PushNotificationPlugin(registrar, channel);
    registrar.addNewIntentListener(plugin);
    channel.setMethodCallHandler(plugin);
  }

  private PushNotificationPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar = registrar;
    this.channel = channel;
    FirebaseApp.initializeApp(registrar.context());

    IntentFilter intentFilter = new IntentFilter();
    intentFilter.addAction(FlutterFirebaseMessagingService.ACTION_TOKEN);
    intentFilter.addAction(FlutterFirebaseMessagingService.ACTION_REMOTE_MESSAGE);
    LocalBroadcastManager manager = LocalBroadcastManager.getInstance(registrar.context());
    manager.registerReceiver(this, intentFilter);
  }

  // BroadcastReceiver implementation.
  @Override
  public void onReceive(Context context, Intent intent) {
    String action = intent.getAction();
    Log.d("push notification plugin", "onReceive");
    if (action == null) {
      return;
    }

    if (action.equals(FlutterFirebaseMessagingService.ACTION_TOKEN)) {
      Log.d("push notification plugin", "token recieved");
      String token = intent.getStringExtra(FlutterFirebaseMessagingService.EXTRA_TOKEN);
      if (token != null) {
        Log.d("token", token);
        saveToken(context, token);
        channel.invokeMethod("onToken", token);
      }
    } else if (action.equals(FlutterFirebaseMessagingService.ACTION_REMOTE_MESSAGE)) {
      Log.d("push notification plugin", "message recieved");
      RemoteMessage message = intent.getParcelableExtra(FlutterFirebaseMessagingService.EXTRA_REMOTE_MESSAGE);
      Map<String, Object> content = parseRemoteMessage(message);
      channel.invokeMethod("onMessage", content);
    }
  }

  @NonNull
  private Map<String, Object> parseRemoteMessage(RemoteMessage message) {
    Map<String, Object> content = new HashMap<>();
    content.put("data", message.getData());

    RemoteMessage.Notification notification = message.getNotification();

    Map<String, Object> notificationMap = new HashMap<>();

    String title = notification != null ? notification.getTitle() : null;
    notificationMap.put("title", title);

    String body = notification != null ? notification.getBody() : null;
    notificationMap.put("body", body);

    content.put("notification", notificationMap);
    return content;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if ("configure".equals(call.method)) {

      String token = getToken(registrar.context());

      if (token != null) {
        FlutterFirebaseMessagingService.broadcastToken(registrar.context(), token);
      }

      if (registrar.activity() != null) {
        sendMessageFromIntent("onLaunch", registrar.activity().getIntent());
      }

      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public boolean onNewIntent(Intent intent) {
    Log.d("Plugin", "OnNewIntent");
    boolean res = sendMessageFromIntent("onResume", intent);
    if (res && registrar.activity() != null) {
      Log.d("Plugin", "OnNewIntent => true");
      registrar.activity().setIntent(intent);
    } else {
      Log.d("Plugin", "OnNewIntent => false");
    }

    return res;
  }

  /** @return true if intent contained a message to send. */
  private boolean sendMessageFromIntent(String method, Intent intent) {
    if (CLICK_ACTION_VALUE.equals(intent.getAction())
        || CLICK_ACTION_VALUE.equals(intent.getStringExtra("click_action"))) {
      Map<String, String> message = new HashMap<>();
      Bundle extras = intent.getExtras();

      if (extras == null) {
        return false;
      }

      for (String key : extras.keySet()) {
        Object extra = extras.get(key);
        if (extra != null) {
          message.put(key, extra.toString());
        }
      }

      channel.invokeMethod(method, message);
      return true;
    }
    return false;
  }

  private void saveToken(Context context, String token) {
    SharedPreferences preferences = context.getSharedPreferences(PUSH_NOTIFICATION_PLUGIN_SHARED_PREFERENCE,
        MODE_PRIVATE);
    SharedPreferences.Editor editor = preferences.edit();
    editor.putString(FlutterFirebaseMessagingService.EXTRA_TOKEN, token);
    editor.apply();
  }

  private String getToken(Context context) {
    SharedPreferences preferences = context.getSharedPreferences(PUSH_NOTIFICATION_PLUGIN_SHARED_PREFERENCE,
        MODE_PRIVATE);
    return preferences.getString(FlutterFirebaseMessagingService.EXTRA_TOKEN, null);
  }

}
