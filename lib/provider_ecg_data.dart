import 'dart:async';

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
  BluetoothCharacteristic? writeCharacteristic;

  Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  var isServiceStarted = false;
  var isEnabled = false;

  int ecgDataLength = 0;
  int ppgDataLength = 0;

  List<double> savedEcgLocalDataList = [];
  List<FlSpot> mainEcgSpotsListData = [];
  List<FlSpot> tempEcgSpotsListData = [];
  List<String> mainEcgHexList = [];
  List<double> mainEcgDecimalList = [];
  List<String> tempEcgHexList = [];
  List<double> tempEcgDecimalList = [];

  List<double> savedPpgLocalDataList = [];
  List<FlSpot> mainPpgSpotsListData = [];
  List<FlSpot> tempPpgSpotsListData = [];
  List<String> mainPpgHexList = [];
  List<double> mainPpgDecimalList = [];
  List<String> tempPpgHexList = [];
  List<double> tempPpgDecimalList = [];

  double lastSavedTime = 0;
  double heartRate = 0;
  late Timer timer;

  clearProviderEcgData() {
    devicesList.clear();
    isLoading = false;
    services!.clear();
    readValues = new Map<Guid, List<int>>();
    isServiceStarted = false;

    savedEcgLocalDataList.clear();
    mainEcgSpotsListData.clear();
    tempEcgSpotsListData.clear();
    mainEcgHexList.clear();
    mainEcgDecimalList.clear();
    tempEcgHexList.clear();
    tempEcgDecimalList.clear();

    savedPpgLocalDataList.clear();
    mainPpgSpotsListData.clear();
    tempPpgSpotsListData.clear();
    mainPpgHexList.clear();
    mainPpgDecimalList.clear();
    tempPpgHexList.clear();
    tempPpgDecimalList.clear();

    lastSavedTime = 0;
  }

  setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  setServiceStarted(bool value) {
    isServiceStarted = value;
    notifyListeners();
  }

  setIsEnabled() {
    isEnabled = !isEnabled;
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

  setReadCharacteristic(BluetoothCharacteristic characteristic) async {
    readCharacteristic = characteristic;

    // notifyListeners();
  }

  setWriteCharacteristic(BluetoothCharacteristic characteristic) {
    writeCharacteristic = characteristic;
    // notifyListeners();
  }

  setReadValues(List<int> value) {
    readValues[readCharacteristic!.uuid] = value;
    notifyListeners();
  }

  setSpotsListData() {
    for (int k = 0; k < tempEcgDecimalList.length; k++) {
      mainEcgSpotsListData
          .add(FlSpot(double.tryParse(((mainEcgDecimalList.length + k)).toString()) ?? 0, tempEcgDecimalList[k]));
    }

    for (int k = 0; k < tempPpgDecimalList.length; k++) {
      mainPpgSpotsListData
          .add(FlSpot(double.tryParse(((mainPpgDecimalList.length + k)).toString()) ?? 0, tempPpgDecimalList[k]));
    }

    if (mainEcgSpotsListData.length > yAxisGraphData) {
      tempEcgSpotsListData = mainEcgSpotsListData
          .getRange(mainEcgSpotsListData.length - yAxisGraphData, mainEcgSpotsListData.length)
          .toList();
    } else {
      tempEcgSpotsListData = mainEcgSpotsListData;
    }

    if (mainPpgSpotsListData.length > yAxisGraphData) {
      tempPpgSpotsListData = mainPpgSpotsListData
          .getRange(mainPpgSpotsListData.length - yAxisGraphData, mainPpgSpotsListData.length)
          .toList();
    } else {
      tempPpgSpotsListData = mainPpgSpotsListData;
    }
  }

  storeDataToLocal() async {
    var box = await Hive.openBox<List<double>>('ecg_data');

    List<double> localDataList = await box.get("item") ?? [];
    localDataList.addAll(tempEcgDecimalList);

    await box.put("item", localDataList);

    printLog("local Data saved!....");
  }

  getStoredLocalData() async {
    var box = await Hive.openBox<List<double>>('ecg_data');

    savedEcgLocalDataList = await box.get("item") ?? [];
    printLog(" savedEcgLocalDataList  ${savedEcgLocalDataList.toString()}");
    printLog(" savedEcgLocalDataList length  ${savedEcgLocalDataList.length}");
  }

  clearStoreDataToLocal() async {
    savedEcgLocalDataList.clear();
    mainEcgSpotsListData.clear();
    tempEcgSpotsListData.clear();
    mainEcgHexList.clear();
    mainEcgDecimalList.clear();
    tempEcgHexList.clear();
    tempEcgDecimalList.clear();

    savedPpgLocalDataList.clear();
    mainPpgSpotsListData.clear();
    tempPpgSpotsListData.clear();
    mainPpgHexList.clear();
    mainPpgDecimalList.clear();
    tempPpgHexList.clear();
    tempPpgDecimalList.clear();

    lastSavedTime = 0;

    var box = await Hive.openBox<List<double>>('ecg_data');
    await box.put("item", []);

    // savedEcgLocalDataList = await box.get("item") ?? [];
    // printLog(" cleared savedEcgLocalDataList  ${savedEcgLocalDataList.toString()}");
  }

  void generateGraphValuesList(List<int>? valueList) async {
    if (valueList != null) {
      lastSavedTime = lastSavedTime + 1;

      // for (int i = 0; i < valueList.length; i++) {
      //   mainEcgHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
      // }

      for (int i = 0; i < valueList.length; i++) {
        if (i < 100) {
          mainEcgHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
        } else {
          mainPpgHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
        }
      }

      if (mainEcgHexList.length > (yAxisGraphData * 2) && mainPpgHexList.length > (yAxisGraphData * 2)) {
        tempEcgHexList =
            mainEcgHexList.getRange(mainEcgHexList.length - (yAxisGraphData * 2), mainEcgHexList.length).toList();
        tempPpgHexList =
            mainPpgHexList.getRange(mainPpgHexList.length - (yAxisGraphData * 2), mainPpgHexList.length).toList();
      } else {
        tempEcgHexList = mainEcgHexList;
        tempPpgHexList = mainPpgHexList;
      }

      for (int h = 0; h < tempEcgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = tempEcgHexList[h + 1] + tempEcgHexList[h];
          mainEcgDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }

      for (int h = 0; h < tempPpgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = tempPpgHexList[h + 1] + tempPpgHexList[h];
          mainPpgDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }

      if (mainEcgDecimalList.length > yAxisGraphData) {
        tempEcgDecimalList =
            mainEcgDecimalList.getRange(mainEcgDecimalList.length - yAxisGraphData, mainEcgDecimalList.length).toList();
      } else {
        tempEcgDecimalList = mainEcgDecimalList;
      }

      if (mainPpgDecimalList.length > yAxisGraphData) {
        tempPpgDecimalList =
            mainPpgDecimalList.getRange(mainPpgDecimalList.length - yAxisGraphData, mainPpgDecimalList.length).toList();
      } else {
        tempPpgDecimalList = mainPpgDecimalList;
      }
      storeDataToLocal();
      setSpotsListData();

      printLog("VVV valueList ${valueList.length} ${valueList.toString()} ");
      printLog("VVV mainEcgHexList ${mainEcgHexList.length} ${mainEcgHexList.toString()}");
      printLog("VVV tempEcgHexList ${tempEcgHexList.length} ${tempEcgHexList.toString()}");
      printLog("VVV mainPpgHexList ${mainPpgHexList.length} ${mainPpgHexList.toString()}");
      printLog("VVV tempPpgHexList ${tempPpgHexList.length} ${tempPpgHexList.toString()}");

      // printLog("VVV mainEcgDecimalList ${mainEcgDecimalList.length} ${mainEcgDecimalList.toString()}");
      // printLog("VVV tempEcgDecimalList ${tempEcgDecimalList.length} ${tempEcgDecimalList.toString()}");

      printLog(
          "VVV tempEcgSpotsListData length: ${tempEcgSpotsListData.length} spotsListData: ${tempEcgSpotsListData.toList()}");
      printLog(
          "VVV tempPpgSpotsListData length: ${tempPpgSpotsListData.length} spotsListData: ${tempPpgSpotsListData.toList()}");
    }
  }

  void countHeartRate() {
    timer = Timer(Duration(seconds: 10), () {
      timer.cancel();

      notifyListeners();
    });
  }
}
