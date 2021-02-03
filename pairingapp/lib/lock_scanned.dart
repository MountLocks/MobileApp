import 'package:flutter/material.dart';

class LockScanned extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List args = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mount Pairing App'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Lock QR: {$args[0]}"),
            Text("Scan the QR Code on the Scooter to Continue"),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/scanpublic',
                      arguments: [args[0]]);
                },
                child: Text("Scan"))
          ],
        ),
      ),
    );
  }
}
