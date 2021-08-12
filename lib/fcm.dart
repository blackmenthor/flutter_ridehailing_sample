import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<void> initFirebaseMessaging({
  required String userId,
}) async {
  try {
    print('INIT FIREBASE MESSAGING');
    // https://github.com/FirebaseExtended/flutterfire/issues/1684
    // TODO: looks like onmessage is fired twice for each message
    // need to look into it
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('ON MESSAGE');
      if (!kReleaseMode) print('onMessage: $message');
      handleMessage(message.data);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('ON MESSAGE OPENED APP');
      if (!kReleaseMode) print('onLaunch: $message');
      handleMessage(message.data);
    });
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.deleteToken();
    var token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    if (!kReleaseMode) debugPrint('Firebase messaging token: $token');

    print('CHANGE TOKEN!');
    CollectionReference users =
        FirebaseFirestore.instance.collection('user-data');
    users
        .doc(userId)
        .update({
          'token': token,
        })
        .then((value) {})
        .catchError((error) => print("Failed to update user: $error"));
  } catch (ex) {
    print(ex);
  }
}

Future<void> onBackgroundMessage(RemoteMessage message) async {
  handleMessage(message.data);
  return;
}

void handleMessage(Map<String, dynamic> message) {
  print(message);
  return;
}
