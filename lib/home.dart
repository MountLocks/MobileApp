import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'main.dart';
import 'dart:async';

class Home extends StatelessWidget {
  Home({this.uid});
  final String uid;
  final String title = "QR Scan Demo";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QRCode Demo',
      theme: ThemeData(
        primaryColor: Color(0xff36424f),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController mapController;

  final LatLng _center = const LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String scanResult = '';

  //function that launches the scanner
  Future scanQRCode() async {
    String cameraScanResult = await scanner.scan();
    setState(() {
      scanResult = cameraScanResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
            onPressed: () {
              FirebaseAuth auth = FirebaseAuth.instance;
              auth.signOut().then((res) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
              });
            },
          )
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanQRCode,
        label: Text('Scan to Unlock'),
        icon: Icon(Icons.lock_open),
      ),
    ));
  }
}
