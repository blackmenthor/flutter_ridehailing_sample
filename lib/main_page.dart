import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ride_hailing/fcm.dart';
import 'package:flutter_ride_hailing/idle/idle_page.dart';
import 'package:flutter_ride_hailing/location/location_service.dart';
import 'package:flutter_ride_hailing/login/login_page.dart';
import 'package:flutter_ride_hailing/state.dart';
import 'package:location/location.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  AppState _state = AppState.IDLE;
  User? _user;
  UserType? _userType;
  LocationService? _locationService;
  LocationData? _userLocation;
  List<DocumentSnapshot<Object>>? _driverLocations;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _locationService = LocationService(
        onLocationChanged: (location) async {
          if (_user != null &&
              location.latitude != null &&
              location.longitude != null) {
            CollectionReference users =
                FirebaseFirestore.instance.collection('user-data');
            users
                .doc(_user!.uid)
                .update({
                  'last-location':
                      GeoPoint(location.latitude!, location.longitude!),
                })
                .then((value) {})
                .catchError((error) => print("Failed to update user: $error"));

            if (_userType == UserType.USER) {
              // find drivers
              _driverLocations = await LocationService.getUserByLocationNearby(
                  location.latitude!, location.longitude!);
            }
          }
          if (mounted) {
            setState(() {
              _userLocation = location;
            });
          }
        },
      );
      FirebaseAuth.instance.userChanges().listen((User? user) async {
        _user = user;
        if (user != null) {
          CollectionReference users =
              FirebaseFirestore.instance.collection('user-data');
          final data = await users.doc(user.uid).get();
          final type = data.get('type');
          switch (type) {
            case 'DRIVER':
              _userType = UserType.DRIVER;
              break;
            case 'USER':
              _userType = UserType.USER;
              break;
          }
          if (data.get('last-trx')?.isNotEmpty ?? false) {
            setState(() {
              _state = AppState.TRANSIT;
            });
          } else {
            setState(() {
              _state = AppState.IDLE;
            });
          }
          _locationService?.init();
          initFirebaseMessaging(userId: user.uid);
        }
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_user == null) {
      body = LoginPage();
    } else {
      body = IdlePage(
        userLocation: _userLocation,
        user: _user,
        userType: _userType,
        driverLocations: _driverLocations,
        state: _state,
        onStateChanged: (newState) {
          setState(() {
            _state = newState;
          });
        },
      );
    }
    return Scaffold(
      body: body,
    );
  }
}
