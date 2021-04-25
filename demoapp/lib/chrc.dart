import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

import 'package:encrypt/encrypt.dart' as encrypt;

class Chrc extends StatefulWidget {
  @override
  _ChrcState createState() => _ChrcState();
}

class _ChrcState extends State<Chrc> {
  ScanResult _result;
  Characteristic _chrc;
  String _salt;
  String _key;
  DataType _dataType = DataType.hex;
  StreamSubscription<Uint8List> _notifySub;
  TextEditingController _writeCtrl = TextEditingController();
  TextEditingController _readCtrl = TextEditingController();
  TextEditingController _notifyCtrl = TextEditingController();

  @override
  Future<void> didChangeDependencies() async {
    if (_result == null || _chrc == null) {
      List args = ModalRoute.of(context).settings.arguments;
      _result = args[0];
      _chrc = args[1];
      _salt = args[2];
      _key = args[3];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(
          () => _dataType = DataType.values[prefs.getInt('data_type') ?? 0]);
    }
    super.didChangeDependencies();
  }

  @override
  Future<void> dispose() async {
    _notifySub?.cancel();
    super.dispose();
  }

  Future<void> _onDataType(DataType value) async {
    setState(() => _dataType = value);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('data_type', value.index);
  }

  Future<void> _onWrite() async {
    Uint8List data;

    if (_dataType == DataType.hex) {
      List<int> hexList = [];
      for (int i = 0; i < _writeCtrl.text.length; i += 3) {
        hexList.add(
            int.parse(_writeCtrl.text[i] + _writeCtrl.text[i + 1], radix: 16));
      }
      data = Uint8List.fromList(hexList);
    } else {
      final key = encrypt.Key.fromUtf8(_key);
      final iv = encrypt.IV.fromUtf8(_salt);
      final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.ctr, padding: null));

      final encrypted = encrypter.encrypt(_writeCtrl.text, iv: iv);

      data = encrypted.bytes;
    }

    if (data.length > 0) {
      await _chrc.write(data, _chrc.isWritableWithResponse);
    }
  }

  Future<void> _onRead() async {
    CharacteristicWithValue data = await _result.peripheral
        .readCharacteristic(_chrc.service.uuid, _chrc.uuid);

    if (_dataType == DataType.hex) {
      setState(() {
        _readCtrl.text = '';
        for (int hex in data.value) {
          _readCtrl.text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
        }
      });
    } else {
      setState(() => _readCtrl.text = String.fromCharCodes(data.value));
    }
  }

  Future<void> _onNotify() async {
    if (_notifySub == null) {
      _notifySub = _chrc.monitor().listen((Uint8List data) {
        if (_dataType == DataType.hex) {
          setState(() {
            _notifyCtrl.text = '';
            for (int hex in data) {
              _notifyCtrl.text +=
                  hex.toRadixString(16).padLeft(2, '0').padRight(3);
            }
          });
        } else {
          setState(() => _notifyCtrl.text = String.fromCharCodes(data));
        }
      });
      setState(() => null);
    } else {
      await _notifySub.cancel();
      setState(() => _notifySub = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_result.peripheral.name ?? _result.peripheral.identifier),
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    String service = serviceLookup(_chrc.service.uuid);
    service = service != null ? '\n' + service : '';
    String characteristic = characteristicLookup(_chrc.uuid);
    characteristic = characteristic != null ? '\n' + characteristic : '';

    return Column(children: [
      buildSwitches(),
      (_chrc.isWritableWithResponse || _chrc.isWritableWithoutResponse)
          ? buildWrite()
          : SizedBox(),
      _chrc.isReadable ? buildRead() : SizedBox(),
      (_chrc.isNotifiable || _chrc.isIndicatable) ? buildNotify() : SizedBox(),
      Expanded(child: SizedBox()),
      Divider(height: 0),
    ]);
  }

  Widget buildSwitches() {
    return Card(
      child: Row(
        children: [
          buildSwitch('Hex', DataType.hex),
          buildSwitch('String', DataType.string),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 8),
    );
  }

  Widget buildSwitch(String label, DataType value) {
    return FlatButton(
      child: Row(children: [
        Radio(
          value: value,
          groupValue: _dataType,
          onChanged: _onDataType,
        ),
        Text(label, style: TextStyle(fontSize: 16)),
      ]),
      padding: EdgeInsets.only(right: 16),
      onPressed: () => _onDataType(value),
    );
  }

  Widget buildWrite() {
    return Card(
      child: Padding(
        child: Row(
          children: [
            Expanded(
                child: TextField(
              controller: _writeCtrl,
              style: TextStyle(fontFamily: 'monospace'),
              inputFormatters: [HexFormatter(_dataType)],
            )),
            SizedBox(width: 12),
            RaisedButton(
              child: Text('Write'),
              textColor: Theme.of(context).textTheme.button.color,
              onPressed: _onWrite,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }

  Widget buildRead() {
    return Card(
      child: Padding(
        child: Row(
          children: [
            RaisedButton(
              child: Text('Read'),
              textColor: Theme.of(context).textTheme.button.color,
              onPressed: _onRead,
            ),
            SizedBox(width: 12),
            Expanded(
                child: TextField(
              controller: _readCtrl,
              readOnly: true,
              style: TextStyle(fontFamily: 'monospace'),
            )),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }

  Widget buildNotify() {
    return Card(
      child: Padding(
        child: Row(
          children: [
            RaisedButton(
              child: Text('Subscribe'),
              textColor: Theme.of(context).textTheme.button.color,
              color: _notifySub != null ? Colors.indigoAccent[400] : null,
              onPressed: _onNotify,
            ),
            SizedBox(width: 12),
            Expanded(
                child: TextField(
              controller: _notifyCtrl,
              readOnly: true,
              style: TextStyle(fontFamily: 'monospace'),
            )),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }
}
