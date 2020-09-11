import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:coup/firebase/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';

import 'authState.dart';

class UserPresence {
  static final _app = FirebaseApp.instance;
  static final FirebaseDatabase _db = FirebaseDatabase(
    app: _app,
    databaseURL: 'https://mobile-andrews.firebaseio.com/',
  );
  static rtdbAndLocalFsPresence(app) async {
    // All the refs required for updation
    var user = await AuthState().getCurrentUser();
    if (user == null) {
      return null;
    }
    var userStatusDatabaseRef = _db.reference().child('/status/' + user.uid);
    var userStatusFirestoreRef =
        Firestore.instance.collection('status').document(user.uid);

    var isOfflineForDatabase = {
      "state": 'offline',
      "last_changed": ServerValue.timestamp,
    };

    var isOnlineForDatabase = {
      "state": 'online',
      "last_changed": ServerValue.timestamp,
    };

    // Firestore uses a different server timestamp value, so we'll
    // create two more constants for Firestore state.
    var isOfflineForFirestore = {
      "state": 'offline',
      "last_changed": FieldValue.serverTimestamp(),
    };

    var isOnlineForFirestore = {
      "state": 'online',
      "last_changed": FieldValue.serverTimestamp(),
    };
    logEvent('setting_Presence');

    _db
        .reference()
        .child('.info/connected')
        .onValue
        .listen((Event event) async {
      if (event.snapshot.value == false) {
        // Instead of simply returning, we'll also set Firestore's state
        // to 'offline'. This ensures that our Firestore cache is aware
        // of the switch to 'offline.'
        logEvent('isOfflineForFirestore');

        userStatusFirestoreRef.updateData(isOfflineForFirestore);
        return;
      }

      await userStatusDatabaseRef
          .onDisconnect()
          .update(isOfflineForDatabase)
          .then((snap) {
        userStatusDatabaseRef.set(isOnlineForDatabase);
        logEvent('isOnlineForFirestore');

        // We'll also add Firestore set here for when we come online.
        userStatusFirestoreRef.updateData(isOnlineForFirestore);
      });
    });
  }
}
