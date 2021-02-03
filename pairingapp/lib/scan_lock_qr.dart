import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class LockQRScannerView extends StatefulWidget {
  const LockQRScannerView({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LockQRScannerViewState();
}

class _LockQRScannerViewState extends State<LockQRScannerView> {
  QRViewController lockController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'LockQR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      lockController.pauseCamera();
    } else if (Platform.isIOS) {
      lockController.resumeCamera();
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
                await lockController?.toggleFlash();
              }),
          IconButton(
              icon: Icon(Icons.flip_camera_ios),
              onPressed: () async {
                await lockController?.flipCamera();
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
      this.lockController = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      await controller?.pauseCamera();
      await Navigator.pushNamed(context, '/lockscanned',
          arguments: [scanData.code]).whenComplete(() async {
        await controller?.resumeCamera();
      });
    });
  }

  @override
  void dispose() {
    lockController?.dispose();
    super.dispose();
  }
}
