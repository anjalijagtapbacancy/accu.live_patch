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

  Array sgFilteredEcg = Array([]);
  Array filterOPEcg = Array([]);
  List<dynamic> peaksArrayEcg = [];
  double totalOfPeaksEcg = 0;

  Array sgFilteredPpg = Array([]);
  Array filterOPPpg = Array([]);
  List<dynamic> peaksArrayPpg = [];
  double totalOfPeaksPpg = 0;

  int heartRate = 0;
  int heartRatePPG = 0;
  List<double> pttArray = [];

  clearProviderGraphData() {
    devicesList.clear();
    isLoading = false;
    services!.clear();
    readValues = new Map<Guid, List<int>>();
    isServiceStarted = false;
    heartRate = 0;
    heartRatePPG = 0;

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

  setConnectedDevice(BluetoothDevice device, BuildContext context) async {
    services = await device.discoverServices();

    connectedDevice = device;
    notifyListeners();

    Navigator.pop(context);
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
    localEcgDataList.addAll(mainEcgDecimalList);
    await box.put("ecg_graph_data", localEcgDataList);

    List<double> localPpgDataList = await box.get("ppg_graph_data") ?? [];
    localPpgDataList.addAll(mainPpgDecimalList);
    await box.put("ppg_graph_data", localPpgDataList);

    savedEcgLocalDataList = await box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = await box.get("ppg_graph_data") ?? [];
    printLog("local Data saved!.... ecg: ${savedEcgLocalDataList.length} ppg: ${savedPpgLocalDataList.length}");
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

  List<int>? finalList = [];

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

      mainEcgDecimalList.clear();
      for (int h = 0; h < mainEcgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = mainEcgHexList[h + 1] + mainEcgHexList[h];
          mainEcgDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }
      print("sss mainEcgHexList ${mainEcgHexList.length} mainEcgDecimalList ${mainEcgDecimalList.length}");

      // print("yyyy ${mainEcgHexList.length} ${mainEcgDecimalList.toList()}");
      mainPpgDecimalList.clear();
      for (int h = 0; h < mainPpgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = mainPpgHexList[h + 1] + mainPpgHexList[h];
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

      printLog("VVV mainEcgDecimalList ${mainEcgDecimalList.length} ${mainEcgDecimalList.toString()}");
      // printLog("VVV tempEcgDecimalList ${tempEcgDecimalList.length} ${tempEcgDecimalList.toString()}");

      printLog(
          "VVV tempEcgSpotsListData length: ${tempEcgSpotsListData.length} spotsListData: ${tempEcgSpotsListData.toList()}");
      printLog(
          "VVV tempPpgSpotsListData length: ${tempPpgSpotsListData.length} spotsListData: ${tempPpgSpotsListData.toList()}");
    }
  }

  void periodicTask() {
    try {
      if (mainEcgDecimalList.length > filterDataListLength &&
          mainEcgHexList.length > 0 &&
          (mainEcgHexList.length) % periodicTimeInSec == 0) {
        printLog("periodicTask ifff  ecg ............... ${mainEcgHexList.length}");
        countEcgHeartRate();
        countPpgHeartRate();
      } else {
        printLog("periodicTask elsee  ecg ............... ${mainEcgHexList.length}");
      }
    } catch (err) {
      printLog("periodicTask err ${err.toString()}");
    }
  }

  void countEcgHeartRate() {
    sgFilteredEcg = Array([]);
    filterOPEcg = Array([]);

    peaksArrayEcg = [];
    totalOfPeaksEcg = 0;

    var fs = 100;
    var nyq = 0.5 * fs; // design filter
    var cutOff = 20;
    var normalFc = cutOff / nyq;
    var numtaps = 127;
    double _threshold = 0;

    var b = firwin(numtaps, Array([normalFc]));
    sgFilteredEcg = lfilter(
        b,
        Array([1.0]),
        Array(mainEcgDecimalList
            .getRange(mainEcgDecimalList.length - filterDataListLength, mainEcgDecimalList.length)
            .toList())); // filter the signal

    // sgFilteredEcg = lfilter(b, Array([1.0]), Array(ecgData.getRange(0, 500).toList())); // filter the signal

    print("TTT ${tempEcgDecimalList.length} ");
    //final filter output
    var fs1 = 100;
    var nyq1 = 0.5 * fs1; // design filter
    var cutOff1 = 0.5;
    var normalFc1 = cutOff1 / nyq1;
    var numtaps1 = 2747;
    var passZero = 'highpass';

    var b1 = firwin(numtaps1, Array([normalFc1]), pass_zero: passZero);
    filterOPEcg = lfilter(b1, Array([1.0]), sgFilteredEcg); // filter the signal

    printLog("CCC sgFilteredEcg " + sgFilteredEcg.runtimeType.toString() + " " + sgFilteredEcg.length.toString());

    printLog("CCC filterOPEcg " + filterOPEcg.runtimeType.toString() + " " + filterOPEcg.length.toString());
    printLog("CCC " + filterOPEcg.toString());
    _threshold = ((filterOPEcg).reduce(math.max)) * 0.28;
    printLog("CCC max ${(filterOPEcg).reduce(math.max)} _threshold " + _threshold.toString());
    peaksArrayEcg = findPeaks(filterOPEcg, threshold: _threshold);
    printLog("Peaks Length " + peaksArrayEcg.length.toString());
    printLog("Peaks " + peaksArrayEcg.toString());
    for (int i = 0; i < peaksArrayEcg.length; i++) {
      printLog("AAA ${i.toString()} " + peaksArrayEcg[i].length.toString());
      if (i == 0) {
        for (int j = 0; j < peaksArrayEcg[i].length; j++) {
          if (j + 1 < (peaksArrayEcg[i].length)) {
            printLog("jjjj ${j} ${peaksArrayEcg[i][j + 1]} ${peaksArrayEcg[i][j]}");

            var interval = ((peaksArrayEcg[i][j + 1] - peaksArrayEcg[i][j]) / 200);
            printLog("jjjj interval ${interval}");

            totalOfPeaksEcg += ((peaksArrayEcg[i][j + 1] - peaksArrayEcg[i][j]) / 200);
          }
        }
      }
    }
    printLog("totalOfPeaksEcg  " +
        totalOfPeaksEcg.toString() +
        " avg " +
        (totalOfPeaksEcg / (peaksArrayEcg[0].length)).toString());
    heartRate = (60 / (totalOfPeaksEcg / (peaksArrayEcg[0].length))).round();
    // heartRate = ((60 * peaksArrayEcg[0].length) / 2.5).round();

    printLog("heartRate:  " + heartRate.toString());
    // notifyListeners();
  }

  void countPpgHeartRate() {
    sgFilteredPpg = Array([]);
    filterOPPpg = Array([]);

    peaksArrayPpg = [];
    totalOfPeaksPpg = 0;

    var fs = 200;
    var nyq = 0.5 * fs; // design filter
    var cutOff = 10;
    var normalFc = cutOff / nyq;
    var numtaps = 506;
    double _threshold = 0;

    var b = firwin(numtaps, Array([normalFc]));
    sgFilteredPpg = lfilter(
        b,
        Array([1.0]),
        Array(mainPpgDecimalList
            .getRange(mainPpgDecimalList.length - filterDataListLength, mainPpgDecimalList.length)
            .toList())); // filter the signal

    // sgFilteredPpg = lfilter(b, Array([1.0]), Array(ecgData.getRange(0, 500).toList())); // filter the signal

    //final filter output
    var fs1 = 100;
    var nyq1 = 0.5 * fs1; // design filter
    var cutOff1 = 0.5;
    var normalFc1 = cutOff1 / nyq1;
    var numtaps1 = 2747;
    var passZero = 'highpass';

    var b1 = firwin(numtaps1, Array([normalFc1]), pass_zero: passZero);
    filterOPPpg = lfilter(b1, Array([1.0]), sgFilteredPpg); // filter the signal

    printLog("CCC sgFilteredPpg " + sgFilteredPpg.runtimeType.toString() + " " + sgFilteredPpg.length.toString());

    printLog("CCC filterOPPpg " + filterOPPpg.runtimeType.toString() + " " + filterOPPpg.length.toString());
    printLog("CCC " + filterOPPpg.toString());
    // _threshold = ((filterOPPpg).reduce(math.max)) * 0.6;
    _threshold = 500;
    // _threshold = (filterOPPpg).reduce((a, b) => a + b) / filterOPPpg.length;

    printLog("CCC _thresholdPpg max ${(filterOPPpg).reduce(math.max)} hhh " + _threshold.toString());
    peaksArrayPpg = findPeaks(filterOPPpg, threshold: _threshold);
    printLog("Peaks Ppg Length " + peaksArrayPpg.length.toString());
    printLog("Peaks Ppg" + peaksArrayPpg.toString());

    List<dynamic> tempPeakList = [];
    int index = 0;
    print("peaksArray.length ${peaksArrayEcg[index].length} ${peaksArrayPpg[index].length}");
    if (peaksArrayEcg[index].length < peaksArrayPpg[index].length) {
      tempPeakList = peaksArrayEcg[index];
    } else {
      tempPeakList = peaksArrayPpg[index];
    }
    pttArray.clear();
    for (int p = 0; p < tempPeakList.length; p++) {
      if (p + 1 < tempPeakList.length) {
        print("uuu ecg ${p.toString()} ${peaksArrayEcg[index][p].toString()}");
        print("uuu ppg ${p.toString()} ${peaksArrayPpg[index][p].toString()}");

        if (peaksArrayEcg[index][p] < peaksArrayPpg[index][p] &&
            peaksArrayEcg[index][p + 1] > peaksArrayPpg[index][p]) {
          pttArray.add((peaksArrayPpg[index][p] - peaksArrayEcg[index][p]) / 200);
          totalOfPeaksPpg += (peaksArrayPpg[index][p] - peaksArrayEcg[index][p]) / 200;
        }
      }
    }
    printLog("pttArray_length:  ${pttArray.length} array: ${pttArray.toString()}");

    printLog(
        "totalOfPeaksPpg  " + totalOfPeaksPpg.toString() + " avg " + (totalOfPeaksPpg / (pttArray.length)).toString());

    heartRatePPG = (60 / (totalOfPeaksPpg / (peaksArrayPpg[0].length))).round();
    // heartRatePPG = ((60 * peaksArrayPpg[0].length) / 2.5).round();

    printLog("heartRatePPG :  " + heartRatePPG.toString());
  }
}
