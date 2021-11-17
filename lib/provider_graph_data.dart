import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:hive/hive.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart/numdart.dart';
import 'dart:math' as math;

class ProviderGraphData with ChangeNotifier, Constant {
  List<BluetoothDevice> devicesList = [];

  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;

  bool isLoading = false;
  BluetoothCharacteristic? readCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;

  Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  var isServiceStarted = false;
  var isEnabled = true;

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
  late Timer timer;

  Array sgFiltered = Array([]);
  Array filterOP = Array([]);

  List<dynamic> peaksArrayFirst = [];
  double avgOfPeaks = 0;
  double totalOfPeaksFirst = 0;

  int heartRate = 0;

  clearProviderGraphData() {
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
      // if ((mainEcgSpotsListData.length) + 1 / periodicTimeInSec == 0) {

      mainEcgSpotsListData
          .add(FlSpot(double.tryParse(((mainEcgDecimalList.length + k)).toString()) ?? 0, tempEcgDecimalList[k]));
    }

    for (int k = 0; k < tempPpgDecimalList.length; k++) {
      mainPpgSpotsListData
          .add(FlSpot(double.tryParse(((mainPpgDecimalList.length + k)).toString()) ?? 0, tempPpgDecimalList[k]));
    }
    if (isEnabled) {
      periodicTask();
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

  storedDataToLocal() async {
    var box = await Hive.openBox<List<double>>('graph_data');

    List<double> localEcgDataList = await box.get("ecg_graph_data") ?? [];
    localEcgDataList.addAll(tempEcgDecimalList);
    await box.put("ecg_graph_data", localEcgDataList);

    List<double> localPpgDataList = await box.get("ppg_graph_data") ?? [];
    localPpgDataList.addAll(tempPpgDecimalList);
    await box.put("ppg_graph_data", localPpgDataList);

    printLog("local Data saved!....");
  }

  getStoredLocalData() async {
    var box = await Hive.openBox<List<double>>('graph_data');

    savedEcgLocalDataList = await box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = await box.get("ppg_graph_data") ?? [];

    printLog("BBB savedEcgLocalDataList length  ${savedEcgLocalDataList.length}");
    printLog("BBB savedPpgLocalDataList length  ${savedPpgLocalDataList.length}");

    printLog("BBB savedEcgLocalDataList  ${savedEcgLocalDataList.toString()}");
    printLog("BBB savedPpgLocalDataList  ${savedPpgLocalDataList.toString()}");
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

    var box = await Hive.openBox<List<double>>('graph_data');
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
        if (i < (valueListLength / 2)) {
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

  void periodicTask() {
    // if ((h + 1) % 5 == 0) {
    try {
      if (mainEcgSpotsListData.length > 0 && (mainEcgSpotsListData.length) % periodicTimeInSec == 0) {
        printLog("periodicTask ifff  ecg ............... ${mainEcgSpotsListData.length}");
        countHeartRate();
      } else {
        printLog("periodicTask elsee  ecg ............... ${mainEcgSpotsListData.length}");
      }
    } catch (err) {
      printLog("periodicTask err ${err.toString()}");
    }
  }

  void countHeartRate() {
    // timer = Timer(Duration(seconds: 10), () {
    //   timer.cancel();

    //   notifyListeners();
    // });

    var fs = 120;
    var nyq = 0.5 * fs; // design filter
    var cutOff = 20;
    var normalFc = cutOff / nyq;
    var numtaps = 152;
    double _threshold = 0;

    var b = firwin(numtaps, Array([normalFc]));
    sgFiltered = lfilter(b, Array([1.0]), Array(tempEcgDecimalList.toList())); // filter the signal

    //final filter output
    var fs1 = 25;
    var nyq1 = 0.5 * fs1; // design filter
    var cutOff1 = 0.5;
    var normalFc1 = cutOff1 / nyq1;
    var numtaps1 = 687;
    var passZero = 'highpass';

    var b1 = firwin(numtaps1, Array([normalFc1]), pass_zero: passZero);
    filterOP = lfilter(b1, Array([1.0]), sgFiltered); // filter the signal

    printLog("CCC sgFiltered " + sgFiltered.runtimeType.toString() + " " + sgFiltered.length.toString());

    printLog("CCC filterOP " + filterOP.runtimeType.toString() + " " + filterOP.length.toString());
    printLog("CCC " + filterOP.toString());
    _threshold = ((filterOP).reduce(math.max)) * 0.3;
    printLog("CCC _threshold " + _threshold.toString());
    peaksArrayFirst = findPeaks(filterOP, threshold: _threshold);
    printLog("Peaks Length " + peaksArrayFirst.length.toString());
    printLog("Peaks " + peaksArrayFirst.toString());
    for (int i = 0; i < peaksArrayFirst.length; i++) {
      printLog("AAA ${i.toString()} " + peaksArrayFirst[i].length.toString());
      if (i == 0) {
        for (int j = 0; j < peaksArrayFirst[i].length; j++) {
          if (j + 1 < (peaksArrayFirst[i].length)) {
            printLog("jjjj ${j} ${peaksArrayFirst[i][j + 1]} ${peaksArrayFirst[i][j]}");

            var interval = ((peaksArrayFirst[i][j + 1] - peaksArrayFirst[i][j]) / 200);
            printLog("jjjj interval ${interval}");

            totalOfPeaksFirst += ((peaksArrayFirst[i][j + 1] - peaksArrayFirst[i][j]) / 200);
          }
        }
      }
    }
    printLog("totalOfPeaksFirst  " +
        totalOfPeaksFirst.toString() +
        " avg " +
        (totalOfPeaksFirst / (peaksArrayFirst[0].length)).toString());
    heartRate = (60 / (totalOfPeaksFirst / (peaksArrayFirst[0].length))).round();
    printLog("heartRate:  " + heartRate.toString());
    // notifyListeners();
  }
}
