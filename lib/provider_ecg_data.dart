import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hive/hive.dart';

class ProviderEcgData with ChangeNotifier {
  final List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  bool isLoading = false;
  BluetoothCharacteristic? readCharacteristic;
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  var isServiceStarted = false;
  List<double> savedLocalDataList = [];
  List<FlSpot> mainSpotsListData = [];
  List<FlSpot> tempSpotsListData = [];

  setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  setServiceStarted(bool value) {
    isServiceStarted = value;
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
    // notifyListeners();
  }

  setReadValues(List<int> value) {
    readValues[readCharacteristic!.uuid] = value;
    notifyListeners();
  }

  setSpotsListData(List<double> tempDecimalList, List<double> mainDecimalList) {
    for (int k = 0; k < tempDecimalList.length; k++) {
      print("mainSpotsListData  ${mainSpotsListData.length}");

      mainSpotsListData.add(FlSpot(double.tryParse((mainDecimalList.length + k).toString()) ?? 0, tempDecimalList[k]));
    }
    tempSpotsListData = mainSpotsListData.getRange(mainSpotsListData.length - 500, mainSpotsListData.length).toList();
  }

  storeDataToLocal(List<double> decimalList) async {
    var box = await Hive.openBox<List<double>>('ecg_data');

    List<double> localDataList = await box.get("item") ?? [];
    localDataList.addAll(decimalList);

    await box.put("item", localDataList);
    print("BBB local Data saved!");
    savedLocalDataList = box.get("item") ?? [];

    // notifyListeners();

    // await box.add(localDataList);
    // var nn =box.values.toList();

    // print("savedLocalDataList type ${box.values.toString()}");
  }

  getStoreDataToLocal() async {
    // var box = await Hive.openBox<List<double>>('ecg_data');

    // savedLocalDataList = await box.get("item") ?? [];
    print("BBB savedLocalDataList  ${savedLocalDataList.toString()}");
    print("BBB savedLocalDataList length  ${savedLocalDataList.length}");
  }

  clearStoreDataToLocal() async {
    mainSpotsListData.clear();
    savedLocalDataList.clear();

    var box = await Hive.openBox<List<double>>('ecg_data');
    await box.put("item", []);
  }
}
