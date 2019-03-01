package com.bluechilli.pushnotification;

import android.content.Context;
import android.content.Intent;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class FlutterFirebaseMessagingService extends FirebaseMessagingService {

    public static final String ACTION_REMOTE_MESSAGE =
            "com.bluechilli.plugins.pushnotification.NOTIFICATION";
    public static final String EXTRA_REMOTE_MESSAGE = "notification";

    public static final String ACTION_TOKEN = "com.bluechilli.plugins.pushnotification.TOKEN";
    public static final String EXTRA_TOKEN = "token";


    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Intent intent = new Intent(ACTION_REMOTE_MESSAGE);
        intent.putExtra(EXTRA_REMOTE_MESSAGE, remoteMessage);
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }


    @Override
    public void onDeletedMessages() {
        super.onDeletedMessages();
    }

    @Override
    public void onMessageSent(String s) {
        super.onMessageSent(s);
    }

    @Override
    public void onSendError(String s, Exception e) {
        super.onSendError(s, e);
    }


    /**
     * Called when token is received.
     *
     * @param token for FCM.
     */
    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        broadcastToken(this, token);
    }

    public static void broadcastToken(Context context, String token) {
        Intent intent = new Intent(ACTION_TOKEN);
        intent.putExtra(EXTRA_TOKEN, token);
        LocalBroadcastManager.getInstance(context).sendBroadcast(intent);
    }

}