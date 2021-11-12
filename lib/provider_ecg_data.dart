import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:hive/hive.dart';

class ProviderEcgData with ChangeNotifier, Constant {
  List<BluetoothDevice> devicesList = [];

  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;

  bool isLoading = false;
  BluetoothCharacteristic? readCharacteristic;
  Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  var isServiceStarted = false;
  List<double> savedLocalDataList = [];
  List<FlSpot> mainSpotsListData = [];
  List<FlSpot> tempSpotsListData = [];

  List<String> mainHexList = [];
  List<double> mainDecimalList = [];
  List<String> tempHexList = [];
  List<double> tempDecimalList = [];

  clearProviderEcgData() {
    devicesList.clear();
    isLoading = false;
    services!.clear();
    readValues = new Map<Guid, List<int>>();
    isServiceStarted = false;
    savedLocalDataList.clear();
    mainSpotsListData.clear();
    tempSpotsListData.clear();

    mainHexList.clear();
    mainDecimalList.clear();
    tempHexList.clear();
    tempDecimalList.clear();
  }

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

  setConnectedDevice(BluetoothDevice device) async {
    services = await device.discoverServices();
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
      printLog("mainSpotsListData  ${mainSpotsListData.length}");

      mainSpotsListData.add(FlSpot(double.tryParse((mainDecimalList.length + k).toString()) ?? 0, tempDecimalList[k]));
    }
    if (mainSpotsListData.length > 500) {
      tempSpotsListData = mainSpotsListData.getRange(mainSpotsListData.length - 500, mainSpotsListData.length).toList();
    } else {
      tempSpotsListData = mainSpotsListData;
    }
  }

  storeDataToLocal() async {
    var box = await Hive.openBox<List<double>>('ecg_data');

    List<double> localDataList = await box.get("item") ?? [];
    localDataList.addAll(tempDecimalList);

    await box.put("item", localDataList);

    printLog("local Data saved!....");

    // notifyListeners();

    // await box.add(localDataList);
    // var nn =box.values.toList();

    // printLog"savedLocalDataList type ${box.values.toString()}");
  }

  getStoredLocalData() async {
    var box = await Hive.openBox<List<double>>('ecg_data');

    savedLocalDataList = await box.get("item") ?? [];
    printLog(" savedLocalDataList  ${savedLocalDataList.toString()}");
    printLog(" savedLocalDataList length  ${savedLocalDataList.length}");
  }

  clearStoreDataToLocal() async {
    mainSpotsListData.clear();
    tempSpotsListData.clear();
    savedLocalDataList.clear();

    mainHexList.clear();
    mainDecimalList.clear();

    tempHexList.clear();
    tempDecimalList.clear();

    var box = await Hive.openBox<List<double>>('ecg_data');
    await box.put("item", []);

    savedLocalDataList = await box.get("item") ?? [];
    printLog(" cleared savedLocalDataList  ${savedLocalDataList.toString()}");
  }

  void generateGraphValuesList(List<int>? valueList) async {
    // await Future.delayed(Duration(microseconds: 200));

    if (valueList != null) {
      printLog("VVV valueList ${valueList.toString()}");

      for (int i = 0; i < valueList.length; i++) {
        mainHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
      }

      if (mainHexList.length > 1000) {
        tempHexList = mainHexList.getRange(mainHexList.length - 1000, mainHexList.length).toList();
      } else {
        tempHexList = mainHexList;
      }
      for (int h = 0; h < tempHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = tempHexList[h + 1] + tempHexList[h];
          mainDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }

      if (mainDecimalList.length > 500) {
        tempDecimalList = mainDecimalList.getRange(mainDecimalList.length - 500, mainDecimalList.length).toList();
      } else {
        tempDecimalList = mainDecimalList;
      }
      storeDataToLocal();
      setSpotsListData(tempDecimalList, mainDecimalList);

      // printLog"VVV valueList ${valueList.length} ${valueList.toString()} ");
      // printLog"VVV mainHexList ${mainHexList.length} ${mainHexList.toString()}");
      // printLog"VVV tempHexList ${tempHexList.length} ${tempHexList.toString()}");

      // printLog"VVV mainDecimalList ${mainDecimalList.length} ${mainDecimalList.toString()}");
      // printLog"VVV tempDecimalList ${tempDecimalList.length} ${tempDecimalList.toString()}");

      printLog(
          "VVV tempSpotsListData length: ${tempSpotsListData.length} spotsListData: ${tempSpotsListData.toList()}");
    }
  }
}
