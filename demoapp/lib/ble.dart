import 'dart:async';
import 'dart:io';
import 'package:circle_wave_progress/circle_wave_progress.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:location/location.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

enum Connection { connecting, discovering }

class BleDevice {
  ScanResult result;
  DateTime when;
  BleDevice(this.result, this.when);
}

class BLEScanner extends StatefulWidget {
  _BLEScannerState createState() => _BLEScannerState();
}

class _BLEScannerState extends State<BLEScanner> with WidgetsBindingObserver {
  BleManager _bleManager = BleManager();
  List<BleDevice> _devices = [];
  Connection _connection;
  StreamSubscription<PeripheralConnectionState> _connSub;
  Timer _cleanupTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ModalRoute.of(context).isCurrent) {
      switch (state) {
        case AppLifecycleState.paused:
          _stopScan();
          break;
        case AppLifecycleState.resumed:
          _startScan();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initStateAsync();
    super.initState();
  }

  Future<void> initStateAsync() async {
    await assignedNumbersLoad();
    await _bleManager.createClient();
    await for (BluetoothState state in _bleManager.observeBluetoothState()) {
      if (state == BluetoothState.POWERED_ON) {
        break;
      }
    }
    _startScan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScan();
    _bleManager.destroyClient();
    super.dispose();
  }

  Future<void> _startScan() async {
    List args = ModalRoute.of(context).settings.arguments;
    if (Platform.isAndroid) {
      if (await _bleManager.bluetoothState() == BluetoothState.POWERED_OFF) {
        await _bleManager.enableRadio();
      }

      AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 23) {
        Location location = Location();
        while (await location.hasPermission() != PermissionStatus.granted) {
          await location.requestPermission();
        }
        if (!await location.serviceEnabled()) {
          await location.requestService();
        }
      }

      _cleanupTimer = Timer.periodic(Duration(seconds: 2), _cleanup);
    }
    _bleManager
        .startPeripheralScan(scanMode: ScanMode.balanced)
        .listen((ScanResult result) {
      if (result.peripheral.name == args[0]) {
        BleDevice device = BleDevice(result, DateTime.now());
        int index = _devices.indexWhere((dynamic _device) =>
            _device.result.peripheral.identifier ==
            device.result.peripheral.identifier);

        setState(() {
          if (index < 0)
            _devices.add(device);
          else
            _devices[index] = device;
        });
      }
    });
  }

  void _cleanup(Timer timer) {
    DateTime limit = DateTime.now().subtract(Duration(seconds: 5));
    for (int i = _devices.length - 1; i >= 0; i--) {
      if (_devices[i].when.isBefore(limit))
        setState(() => _devices.removeAt(i));
    }
  }

  Future<void> _stopScan() async {
    _cleanupTimer?.cancel();
    await _bleManager.stopPeripheralScan();
    if (mounted) {
      setState(() => _devices.clear());
    }
  }

  Future<void> _restartScan() async {
    if (Platform.isAndroid) {
      setState(() => _devices.clear());
    } else {
      await _stopScan();
      _startScan();
    }
  }

  Future<void> _gotoDevice(int index) async {
    ScanResult result = _devices[index].result;
    _stopScan();

    try {
      setState(() => _connection = Connection.connecting);
      await result.peripheral
          .connect(refreshGatt: true, timeout: Duration(seconds: 15));
      _connSub = result.peripheral
          .observeConnectionState(completeOnDisconnect: true)
          .listen((PeripheralConnectionState state) {
        if (state == PeripheralConnectionState.disconnected) {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      });
      await result.peripheral.requestMtu(251);

      setState(() => _connection = Connection.discovering);
      await result.peripheral.discoverAllServicesAndCharacteristics();

      var key = new StringBuffer();

      List<Service> services = await result.peripheral.services();

      Service deviceInformationService =
          services.firstWhere((service) => service.uuid.contains('180a'));

      Service nordicUARTService =
          services.firstWhere((service) => service.uuid.contains('ca9e'));

      List<Characteristic> deviceInformationServiceCharacteristics =
          await deviceInformationService.characteristics();

      List<Characteristic> nordicUARTServiceCharacteristics =
          await nordicUARTService.characteristics();

      Characteristic manufacturerNameCharacteristic =
          deviceInformationServiceCharacteristics.firstWhere(
              (characteristic) => characteristic.uuid.contains("2a29"));

      Characteristic serialNumberCharacteristic =
          deviceInformationServiceCharacteristics.firstWhere(
              (characteristic) => characteristic.uuid.contains("2a25"));

      Characteristic saltCharacteristic =
          nordicUARTServiceCharacteristics.firstWhere(
              (characteristic) => characteristic.uuid.contains("6e400003"));

      Characteristic rxCharacteristic =
          nordicUARTServiceCharacteristics.firstWhere(
              (characteristic) => characteristic.uuid.contains("6e400002"));

      String manufacturerName =
          String.fromCharCodes(await manufacturerNameCharacteristic.read());

      String serialNumber =
          String.fromCharCodes(await serialNumberCharacteristic.read());

      String salt = String.fromCharCodes(await saltCharacteristic.read());

      key.writeAll([manufacturerName, serialNumber], " ");

      Navigator.pushNamed(context, '/chrc', arguments: [
        result,
        rxCharacteristic,
        salt,
        key.toString().padRight(32, "0")
      ]).whenComplete(() async {
        _connSub?.cancel();
        if (await result.peripheral.isConnected()) {
          result.peripheral.disconnectOrCancelConnection();
        }
        setState(() => _connection = null);
        _startScan();
      });
    } on BleError {
      _connSub?.cancel();
      setState(() => _connection = null);
      _startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mount Demo App'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _connection == null ? _restartScan : null,
          )
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (_connection != null) {
      switch (_connection) {
        case Connection.connecting:
          return loader('Connecting ...', 'Wait while connecting');
        case Connection.discovering:
          return loader('Connecting ...', 'Wait while discovering services');
      }
    }
    if (_devices.length == 0) return buildIntro();
    return buildList();
  }

  Widget buildIntro() {
    final screen = MediaQuery.of(context).size;

    return Column(
      children: [
        Stack(
          children: [
            Material(
              child: CircleWaveProgress(
                size: screen.width * .80,
                borderWidth: 10.0,
                backgroundColor: Colors.transparent,
                borderColor: Colors.white,
                waveColor: Colors.white70,
                progress: 50,
              ),
              elevation: 3,
              color: Colors.grey[200],
              shape: CircleBorder(),
            ),
            Opacity(
              child: Padding(
                child: Icon(
                  Icons.bluetooth_searching,
                  color: Colors.indigo,
                  size: screen.width / 2,
                ),
                padding: EdgeInsets.only(left: screen.width / 14),
              ),
              opacity: .90,
            ),
          ],
          alignment: AlignmentDirectional.center,
        ),
        Text(
          'No BLE devices found',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
        Padding(
          child: Text(
            'Wait while looking for BLE devices.\nThis should take a few seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          padding: EdgeInsets.only(bottom: screen.height * .02),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }

  Widget buildList() {
    return RefreshIndicator(
      child: ListView.separated(
        itemCount: _devices.length + 1,
        itemBuilder: buildListItem,
        separatorBuilder: (BuildContext context, int index) =>
            Divider(height: 0),
      ),
      onRefresh: _restartScan,
    );
  }

  Widget buildListItem(BuildContext context, int index) {
    if (index == 0) return infobar(context, 'BLE devices');

    ScanResult result = _devices[index - 1].result;
    String vendor = vendorLookup(result.advertisementData.manufacturerData);
    vendor = vendor != null ? '\n' + vendor : '';

    return Card(
      child: ListTile(
        leading: Column(
          children: [Text('${result.rssi.toString()} dB')],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        title: result.peripheral.name != null
            ? Text(result.peripheral.name)
            : Text('Unnamed',
                style: TextStyle(
                    color: Theme.of(context).textTheme.caption.color)),
        subtitle: Text(result.peripheral.identifier + vendor,
            style: TextStyle(height: 1.35)),
        trailing: Column(
          children: [Icon(Icons.chevron_right)],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        isThreeLine: vendor.length > 0,
        onTap: () => _gotoDevice(index - 1),
      ),
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(),
    );
  }
}
