import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Map<int, String> asgnVendor = {};
Map<String, String> asgnService = {};
Map<String, String> asgnCharacteristic = {};
RegExp pattern = RegExp(r'^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$',
    caseSensitive: false);

Future<void> assignedNumbersLoad() async {
  final vendors = await rootBundle
      .loadString('bluetooth-numbers-database/v1/company_ids.json');
  for (final data in jsonDecode(vendors)) {
    asgnVendor[data['code']] = data['name'];
  }

  final services = await rootBundle
      .loadString('bluetooth-numbers-database/v1/service_uuids.json');
  for (final data in jsonDecode(services)) {
    asgnService[data['uuid']] = data['name'];
  }

  final characteristics = await rootBundle
      .loadString('bluetooth-numbers-database/v1/characteristic_uuids.json');
  for (final data in jsonDecode(characteristics)) {
    asgnCharacteristic[data['uuid']] = data['name'];
  }
}

String vendorLookup(Uint8List data) {
  if (data != null) {
    final int id = data[0] + (data[1] << 8);
    if (asgnVendor.containsKey(id)) return asgnVendor[id];
  }
  return null;
}

String serviceLookup(String uuid) {
  RegExpMatch match = pattern.firstMatch(uuid);
  if (match != null) uuid = match.group(1);
  uuid = uuid.toUpperCase();
  if (asgnService.containsKey(uuid)) return asgnService[uuid];
  return null;
}

String characteristicLookup(String uuid) {
  RegExpMatch match = pattern.firstMatch(uuid);
  if (match != null) uuid = match.group(1);
  uuid = uuid.toUpperCase();
  if (asgnCharacteristic.containsKey(uuid)) return asgnCharacteristic[uuid];
  return null;
}
