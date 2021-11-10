import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ProviderEcgData with ChangeNotifier {
  final List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  bool isLoading = false;
  BluetoothCharacteristic? readCharacteristic;
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  setDeviceList(BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      devicesList.add(device);
    }
    notifyListeners();
  }

  setConnectedDevice(BluetoothDevice device) {
    connectedDevice = device;
    notifyListeners();
  }

  setReadCharacteristic(BluetoothCharacteristic characteristic) {
    readCharacteristic = characteristic;
    notifyListeners();
  }

  setReadValues(List<int> value) {
    readValues[readCharacteristic!.uuid] = value;
    notifyListeners();
  }
}
