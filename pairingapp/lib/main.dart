import 'ble.dart';
import 'srvc.dart';
import 'chrc.dart';
import 'widgets.dart';
import 'lock_scanned.dart';
import 'scan_lock_qr.dart';
import 'scan_public_qr.dart';
import 'package:flutter/material.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mount Pairing App',
      debugShowCheckedModeBanner: false,
      home: Main(),
      routes: {
        '/ble': (BuildContext context) => BLEScanner(),
        '/scanlock': (BuildContext context) => LockQRScannerView(),
        '/lockscanned': (BuildContext context) => LockScanned(),
        '/scanpublic': (BuildContext context) => PublicQRScannerView(),
        '/srvc': (BuildContext context) => Srvc(),
        '/chrc': (BuildContext context) => Chrc(),
      },
      theme: appTheme(),
    );
  }
}

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mount Pairing App'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Text("Scan the QR Code on the Lock to Start"),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/scanlock');
                },
                child: Text("Scan"))
          ],
        ),
      ),
    );
  }
}
