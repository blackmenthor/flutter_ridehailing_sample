import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ride_hailing/state.dart';

class BottomIdleWidget extends StatefulWidget {
  final User? user;
  final UserType? userType;

  BottomIdleWidget({
    this.user,
    this.userType,
  });

  @override
  _BottomIdleWidgetState createState() => _BottomIdleWidgetState();
}

class _BottomIdleWidgetState extends State<BottomIdleWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100.0,
      decoration: BoxDecoration(
          color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
      child: Center(
        child: Text(
          'Halo, ${widget.user?.email ?? '-'}, \n'
          '${widget.userType == UserType.DRIVER ? 'menunggu customer...' : 'Silakan tekan lama pada map utk menentukan tujuan'}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
