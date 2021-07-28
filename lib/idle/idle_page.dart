import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ride_hailing/components/base_scaffold.dart';
import 'package:flutter_ride_hailing/idle/bottom_idle_widget.dart';
import 'package:flutter_ride_hailing/location/location_service.dart';
import 'package:flutter_ride_hailing/state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class IdlePage extends StatefulWidget {
  final LocationData? userLocation;
  final User? user;
  final UserType? userType;
  final List<DocumentSnapshot<Object>>? driverLocations;
  final AppState state;
  final Function(AppState) onStateChanged;

  IdlePage({
    this.userLocation,
    this.user,
    this.userType,
    this.driverLocations,
    required this.state,
    required this.onStateChanged,
  });

  @override
  _IdlePageState createState() => _IdlePageState();
}

class _IdlePageState extends State<IdlePage> {
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _jakarta = CameraPosition(
    target: LatLng(-6.2, 106.816666),
    zoom: 14.4746,
  );
  Set<Marker> _markers = {};
  LatLng? _destinationLatLng;
  DocumentSnapshot? _txnSnapshot;
  TextEditingController _ratingCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      final ctrl = await _controller.future;
      ctrl.animateCamera(CameraUpdate.newCameraPosition(_jakarta));
    });
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  _updateUserLocation() async {
    if (widget.userLocation?.latitude == null ||
        widget.userLocation?.longitude == null) {
      return;
    }
    final marker = Marker(
      markerId: MarkerId(
        'MY_LOCATION',
      ),
      position: LatLng(
        widget.userLocation!.latitude!,
        widget.userLocation!.longitude!,
      ),
      infoWindow: InfoWindow(
        title: 'Lokasimu',
      ),
      icon: BitmapDescriptor.defaultMarker,
    );
    _markers.add(marker);
    final ctrl = await _controller.future;
    ctrl.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          widget.userLocation!.latitude!,
          widget.userLocation!.longitude!,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _updateTxnData() async {
    CollectionReference users =
        FirebaseFirestore.instance.collection('user-data');
    final userData = await users.doc(widget.user!.uid).get();
    if (userData.get('last-trx')?.isNotEmpty ?? false) {
      CollectionReference txns =
          FirebaseFirestore.instance.collection('transaction');
      final txnData = await txns.doc(userData.get('last-trx')).get();
      if (!txnData.exists) return;
      final destination = txnData.get('destination') as GeoPoint;
      setState(() {
        _txnSnapshot = txnData;
        _destinationLatLng = LatLng(
          destination.latitude,
          destination.longitude,
        );
        _markers
            .removeWhere((element) => element.markerId.value == 'DESTINATION');
        _markers.add(
          Marker(
            markerId: MarkerId(
              'DESTINATION',
            ),
            position: LatLng(
              destination.latitude,
              destination.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Tujuanmu',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant IdlePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state != AppState.IDLE) {
      _updateTxnData();
    }

    if (widget.userLocation == null) return;
    _updateUserLocation();
  }

  String get appBar {
    if (_txnSnapshot != null) {
      final txnState = _txnSnapshot!.get('state');
      switch (txnState) {
        case 'PROPOSED':
          return 'Transaction proposed';
        case 'TRANSIT':
          return 'In Transit';
        case 'COMPLETED_DRIVER':
          return 'Waiting for Rating';
      }
    }
    return 'Idle Page';
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appBar,
      actions: [
        PopupMenuButton<String>(
          onSelected: (selected) {
            switch (selected) {
              case 'Logout':
                logout(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return {'Logout'}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: {
              ..._markers,
              if (widget.driverLocations != null) ...[
                ...widget.driverLocations!
                    .where((e) => e.get('type') == 'DRIVER')
                    .where((e) => e.get('last-trx')?.isEmpty ?? true)
                    .map((e) {
                  final id = e.get('id');
                  final loc = e.get('last-location') as GeoPoint;
                  return Marker(
                    markerId: MarkerId(
                      id,
                    ),
                    position: LatLng(
                      loc.latitude,
                      loc.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title: id,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  );
                }).toSet()
              ],
            },
            initialCameraPosition: widget.userLocation == null
                ? _jakarta
                : CameraPosition(
                    target: LatLng(
                      widget.userLocation!.latitude!,
                      widget.userLocation!.longitude!,
                    ),
                    zoom: 14.4746,
                  ),
            onLongPress: widget.userType != UserType.USER ||
                    (widget.state != AppState.IDLE &&
                        widget.state != AppState.BOOKING)
                ? null
                : (newLatLng) async {
                    if (widget.userType == UserType.USER) {
                      // add new marker
                      _markers.removeWhere(
                          (element) => element.markerId.value == 'DESTINATION');
                      _markers.add(
                        Marker(
                          markerId: MarkerId(
                            'DESTINATION',
                          ),
                          position: LatLng(
                            newLatLng.latitude,
                            newLatLng.longitude,
                          ),
                          infoWindow: InfoWindow(
                            title: 'Tujuanmu',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                      );
                      _destinationLatLng = newLatLng;
                      final ctrl = await _controller.future;
                      ctrl.animateCamera(
                        CameraUpdate.newLatLng(newLatLng),
                      );
                      widget.onStateChanged(AppState.BOOKING);

                      if (mounted) setState(() {});
                    }
                  },
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          if (widget.state == AppState.IDLE) ...[
            Positioned(
              bottom: 16.0,
              left: 0.0,
              right: 0.0,
              child: BottomIdleWidget(
                user: widget.user,
                userType: widget.userType,
              ),
            ),
          ],
          if (widget.userType == UserType.USER) ...[
            if (widget.state == AppState.BOOKING) ...[
              Positioned(
                top: 16.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 8.0,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Titik Awal:  ',
                            ),
                            TextSpan(
                              text: widget.userLocation!.latitude!
                                  .toStringAsFixed(2),
                            ),
                            TextSpan(
                              text: '-',
                            ),
                            TextSpan(
                              text: widget.userLocation!.longitude!
                                  .toStringAsFixed(2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Titik Akhir: ',
                            ),
                            TextSpan(
                              text: _destinationLatLng!.latitude
                                  .toStringAsFixed(2),
                            ),
                            TextSpan(
                              text: '-',
                            ),
                            TextSpan(
                              text: _destinationLatLng!.longitude
                                  .toStringAsFixed(2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16.0,
                left: 0.0,
                right: 0.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  child: ElevatedButton(
                    child: Text(
                      'Book',
                    ),
                    onPressed: () async {
                      var availableDrivers =
                          await LocationService.getUserByLocationNearby(
                              widget.userLocation!.latitude!,
                              widget.userLocation!.longitude!);
                      availableDrivers = availableDrivers
                              ?.where((e) => e.get('type') == 'DRIVER')
                              ?.where((e) => e.get('last-trx')?.isEmpty ?? true)
                              ?.toList() ??
                          [];
                      if (availableDrivers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Tidak ada driver tersedia!',
                          ),
                        ));
                        return;
                      }

                      final driver = availableDrivers.first;
                      CollectionReference transactions =
                          FirebaseFirestore.instance.collection('transaction');
                      final result = await transactions.add({
                        'origin': GeoPoint(
                          widget.userLocation!.latitude!,
                          widget.userLocation!.longitude!,
                        ),
                        'destination': GeoPoint(
                          _destinationLatLng!.latitude,
                          _destinationLatLng!.longitude,
                        ),
                        // TODO: SET PRICE
                        'price': '15000',
                        'userId': widget.user!.uid,
                        'driverId': driver.id,
                        'state': 'PROPOSED',
                      });

                      CollectionReference users =
                          FirebaseFirestore.instance.collection('user-data');
                      users.doc(driver.id).update({
                        'last-trx': result.id,
                      });
                      users.doc(widget.user!.uid).update({
                        'last-trx': result.id,
                      });
                      widget.onStateChanged(AppState.TRANSIT);
                    },
                  ),
                ),
              ),
            ],
          ],
          if (widget.state == AppState.TRANSIT &&
              _txnSnapshot?.get('state') == 'PROPOSED') ...[
            Positioned(
              bottom: 16.0,
              left: 0.0,
              right: 0.0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.blueAccent,
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.userType == UserType.DRIVER
                                      ? 'User: '
                                      : 'Driver: ',
                                ),
                                TextSpan(
                                    text: _txnSnapshot!.get(
                                        widget.userType == UserType.DRIVER
                                            ? 'userId'
                                            : 'driverId')),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Origin: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Destination: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.userType == UserType.DRIVER) ...[
                      SizedBox(
                        height: 8.0,
                      ),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            CollectionReference txns = FirebaseFirestore
                                .instance
                                .collection('transaction');
                            txns.doc(_txnSnapshot!.id).update({
                              'state': 'TRANSIT',
                            });
                          },
                          child: Text(
                            'Terima Ride!',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (widget.state == AppState.TRANSIT &&
              _txnSnapshot?.get('state') == 'TRANSIT') ...[
            Positioned(
              bottom: 16.0,
              left: 0.0,
              right: 0.0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.blueAccent,
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.userType == UserType.DRIVER
                                      ? 'User: '
                                      : 'Driver: ',
                                ),
                                TextSpan(
                                    text: _txnSnapshot!.get(
                                        widget.userType == UserType.DRIVER
                                            ? 'userId'
                                            : 'driverId')),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Origin: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Destination: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.userType == UserType.DRIVER) ...[
                      SizedBox(
                        height: 8.0,
                      ),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            CollectionReference txns = FirebaseFirestore
                                .instance
                                .collection('transaction');
                            txns.doc(_txnSnapshot!.id).update({
                              'state': 'COMPLETED_DRIVER',
                            });
                            CollectionReference users = FirebaseFirestore
                                .instance
                                .collection('user-data');
                            users.doc(_txnSnapshot!.get('driverId')).update({
                              'last-trx': null,
                            });
                            _txnSnapshot = null;
                            _destinationLatLng = null;
                            _markers.removeWhere(
                                (e) => e.markerId.value == 'DESTINATION');
                            setState(() {});

                            widget.onStateChanged(AppState.IDLE);
                          },
                          child: Text(
                            'Saya Telah Sampai!',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (widget.userType == UserType.USER &&
              widget.state == AppState.TRANSIT &&
              _txnSnapshot?.get('state') == 'COMPLETED_DRIVER') ...[
            Positioned(
              bottom: 16.0,
              left: 0.0,
              right: 0.0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.blueAccent,
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.userType == UserType.DRIVER
                                      ? 'User: '
                                      : 'Driver: ',
                                ),
                                TextSpan(
                                    text: _txnSnapshot!.get(
                                        widget.userType == UserType.DRIVER
                                            ? 'userId'
                                            : 'driverId')),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Origin: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('origin')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Destination: ',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .latitude
                                      .toStringAsFixed(2),
                                ),
                                TextSpan(
                                  text: ',',
                                ),
                                TextSpan(
                                  text: _txnSnapshot!
                                      .get('destination')
                                      .longitude
                                      .toStringAsFixed(2),
                                ),
                              ],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      color: Colors.white,
                      child: TextField(
                        controller: _ratingCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: 'Rating Driver (1-5)',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final rating = _ratingCtrl.text;
                          if (rating.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Rating harus diisi!',
                              ),
                            ));
                            return;
                          }
                          final ratingInt = int.parse(rating);
                          if (ratingInt < 1 || ratingInt > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Rating salah!',
                              ),
                            ));
                            return;
                          }
                          CollectionReference txns = FirebaseFirestore.instance
                              .collection('transaction');
                          txns.doc(_txnSnapshot!.id).update({
                            'state': 'COMPLETED',
                            'rating': ratingInt,
                          });
                          CollectionReference users = FirebaseFirestore.instance
                              .collection('user-data');
                          users.doc(widget.user!.uid).update({
                            'last-trx': null,
                          });
                          _txnSnapshot = null;
                          _destinationLatLng = null;
                          _markers.removeWhere(
                              (e) => e.markerId.value == 'DESTINATION');
                          setState(() {});

                          widget.onStateChanged(AppState.IDLE);
                        },
                        child: Text(
                          'Rating Driver!',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
