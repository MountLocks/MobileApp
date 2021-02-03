import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class PublicQRScannerView extends StatefulWidget {
  const PublicQRScannerView({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PublicQRScannerViewState();
}

class _PublicQRScannerViewState extends State<PublicQRScannerView> {
  QRViewController publicController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'PublicQR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      publicController.pauseCamera();
    } else if (Platform.isIOS) {
      publicController.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mount Pairing App'),
        actions: [
          IconButton(
              icon: Icon(Icons.flash_on),
              onPressed: () async {
                await publicController?.toggleFlash();
              }),
          IconButton(
              icon: Icon(Icons.flip_camera_ios),
              onPressed: () async {
                await publicController?.flipCamera();
              })
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      cameraFacing: CameraFacing.back,
      onQRViewCreated: _onQRViewCreated,
      formatsAllowed: [BarcodeFormat.qrcode],
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.publicController = controller;
    });
    List args = ModalRoute.of(context).settings.arguments;
    controller.scannedDataStream.listen((scanData) async {
      await controller?.pauseCamera();
      Navigator.pushNamed(context, '/ble', arguments: [args[0], scanData.code])
          .whenComplete(() async {
        await controller?.resumeCamera();
      });
    });
  }

  @override
  void dispose() {
    publicController?.dispose();
    super.dispose();
  }
}
