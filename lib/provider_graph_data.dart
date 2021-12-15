import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/ModelClass/TrainModel.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart/numdart.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'ModelClass/Prediction.dart';

// import 'package:smoothing/smoothing.dart';

class ProviderGraphData with ChangeNotifier, Constant {
  List<BluetoothDevice> devicesList = [];

  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;

  Future<ArrhythmiaType>? arrhythmia_type;

  Location location = new Location();

  bool isLocServiceEnabled = false;
  PermissionStatus? _permissionGranted;
  bool isLoading = false;
  BluetoothCharacteristic? readCharacteristic;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? writeChangeModeCharacteristic;

  Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  var isServiceStarted = false;
  var isEnabled = true;
  var isShowAvailableDevices = true;
  var isScanning = true;

  double spo2Val = 0;

  int tabLength = 3;
  int ecgDataLength = 0;
  int ppgDataLength = 0;
  int tabSelectedIndex = 0;

  List<int> rrIntervalList = [];

  //List<double> HeartRateList = [];
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

  Array sgFilteredEcg = Array([]);
  Array filterOPEcg = Array([]);
  List<dynamic> peaksArrayEcg = [];
  double totalOfPeaksEcg = 0;

  Array sgFilteredPpg = Array([]);
  Array filterOPPpg = Array([]);
  List<dynamic> peaksArrayPpg = [];
  double totalOfPeaksPpg = 0;

  double stepCount = 0;
  int heartRate = 0;
  String heartRatePPG = "";
  List<double> pttArray = [];
  List<int> peaksPositionsEcgArray = [];
  List<int> peaksPositionsPpgArray = [];

  double avgPTT = 0;
  double dBp = 0;
  double dDbp = 0;

  int noiseLength = 0;
  static int frameLength = 11;

  List<double> hrv = [];
  double avgHrv = 0;
  List<double> prv = [];
  double avgPrv = 0;

  // SgFilter filter = new SgFilter(3, frameLength);

  clearProviderGraphData() {
    tabSelectedIndex = 0;
    devicesList.clear();
    isLoading = false;
    services!.clear();
    connectedDevice = null;
    readValues = new Map<Guid, List<int>>();
    isServiceStarted = false;
    heartRate = 0;
    heartRatePPG = "";
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
  }

  /* setTabSelectedIndex(int index) {
    tabSelectedIndex = index;
    //ecg ppg 4
    // sp02 7

    // writeChangeModeCharacteristic!.write([index + 4]);
    // notifyListeners();
  }
*/

  void enableLocation() async {
    isLocServiceEnabled = await location.serviceEnabled();
    if (!isLocServiceEnabled) {
      isLocServiceEnabled = await location.requestService();

      if (!isLocServiceEnabled) {
        return;
      }
    }

    // _permissionGranted = await location.hasPermission();
    // if (_permissionGranted == PermissionStatus.denied) {
    //   _permissionGranted = await location.requestPermission();
    //   if (_permissionGranted != PermissionStatus.granted) {
    //     return;
    //   }
    // }

    notifyListeners();
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

  setIsShowAvailableDevices() {
    isShowAvailableDevices = !isShowAvailableDevices;
    notifyListeners();
  }

  setIsScanning(bool value) {
    isScanning = value;
    notifyListeners();
  }

  setDeviceList(BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      devicesList.add(device);
    }

    notifyListeners();
  }

  setConnectedDevice(BluetoothDevice device, BuildContext context, List<BluetoothService> service) async {
    services = service;
    connectedDevice = device;
    notifyListeners();
  }

  clearConnectedDevice() async {
    services = [];
    connectedDevice = null;
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

  setWriteChangeModeCharacteristic(BluetoothCharacteristic characteristic) {
    writeChangeModeCharacteristic = characteristic;
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

    List<double> localEcgDataList = box.get("ecg_graph_data") ?? [];
    localEcgDataList.addAll(mainEcgDecimalList);
    await box.put("ecg_graph_data", localEcgDataList);

    List<double> localPpgDataList = box.get("ppg_graph_data") ?? [];
    localPpgDataList.addAll(mainPpgDecimalList);
    await box.put("ppg_graph_data", localPpgDataList);

    savedEcgLocalDataList = box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = box.get("ppg_graph_data") ?? [];
    printLog("local Data saved!.... ecg: ${savedEcgLocalDataList.length} ppg: ${savedPpgLocalDataList.length}");
  }

  getStoredLocalData() async {
    var box = await Hive.openBox<List<double>>('graph_data');

    savedEcgLocalDataList = box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = box.get("ppg_graph_data") ?? [];
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

    var box = await Hive.openBox<List<double>>('graph_data');
    await box.put("item", []);

    // savedEcgLocalDataList = await box.get("item") ?? [];
    // printLog(" cleared savedEcgLocalDataList  ${savedEcgLocalDataList.toString()}");
  }

  void getSpo2Data(List<int>? valueList) {
    print("getSpo2Data valueList ${valueList!.length} ${valueList.toList()}");
    if (valueList.length > 1) {
      for (int i = 0; i < valueList.length; i++) {
        print(valueList[i].toRadixString(16).padLeft(2, '0').toString());
      }

      String strHex = valueList[1].toRadixString(16).padLeft(2, '0') + valueList[0].toRadixString(16).padLeft(2, '0');
      print("strHex $strHex");

      spo2Val = (double.parse(int.parse(strHex, radix: 16).toString().padLeft(1, '0'))) / 100;
      print("spo2Val ${spo2Val.toString()}");
    }
    // notifyListeners();
  }

  void generateGraphValuesList(List<int>? valueList) async {
    if (valueList != null && valueList.length > 0) {
      List<int>? stepCountList = [valueList[valueList.length - 2], valueList[valueList.length - 1]];

      List<String> stepCountHexList = [
        stepCountList[0].toRadixString(16).padLeft(2, '0'),
        stepCountList[1].toRadixString(16).padLeft(2, '0')
      ];

      String strStepHex = stepCountHexList[1] + stepCountHexList[0];

      stepCount = double.parse(int.parse(strStepHex, radix: 16).toString());
      printLog("stepCount ${stepCount.toString()}");

      for (int i = 0; i < (valueList.length - 2); i++) {
        if (i < ((valueList.length - 2) / 2)) {
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
      // if (mainEcgDecimalList.length >= frameLength) {
      //   mainEcgDecimalList = filter.smooth(mainEcgDecimalList);
      // }

      mainPpgDecimalList.clear();
      for (int h = 0; h < mainPpgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = mainPpgHexList[h + 1] + mainPpgHexList[h];
          mainPpgDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }
      // if (mainPpgDecimalList.length >= frameLength) {
      //   mainPpgDecimalList = filter.smooth(mainPpgDecimalList);
      // }

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

      // printLog("VVV valueList ${valueList.length} ${valueList.toString()} ");
      // printLog("VVV mainEcgHexList ${mainEcgHexList.length} ${mainEcgHexList.toString()}");
      // printLog("VVV tempEcgHexList ${tempEcgHexList.length} ${tempEcgHexList.toString()}");
      // printLog("VVV mainPpgHexList ${mainPpgHexList.length} ${mainPpgHexList.toString()}");
      // printLog("VVV tempPpgHexList ${tempPpgHexList.length} ${tempPpgHexList.toString()}");
      // printLog("VVV mainEcgDecimalList ${mainEcgDecimalList.length} ${mainEcgDecimalList.toString()}");

      // printLog(
      //     "VVV tempEcgSpotsListData length: ${tempEcgSpotsListData.length} spotsListData: ${tempEcgSpotsListData.toList()}");
      // printLog(
      //     "VVV tempPpgSpotsListData length: ${tempPpgSpotsListData.length} spotsListData: ${tempPpgSpotsListData.toList()}");
      notifyListeners();
    }
  }

  void periodicTask() {
    try {
      if (mainEcgHexList.length > 0 && (mainEcgHexList.length) % periodicTimeInSec == 0) {
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
    if (mainEcgDecimalList.length > filterDataListLength) {
      sgFilteredEcg = lfilter(
          b,
          Array([1.0]),
          Array(mainEcgDecimalList
              .getRange(mainEcgDecimalList.length - filterDataListLength, mainEcgDecimalList.length)
              .toList())); // filter the signal
      print("getRange... ${mainEcgDecimalList.length - filterDataListLength} ${mainEcgDecimalList.length}");
    } else {
      sgFilteredEcg = lfilter(b, Array([1.0]), Array(mainEcgDecimalList)); // filter the signal
    }

    // List<double> result = mainEcgDecimalList
    //     .getRange(mainEcgDecimalList.length - filterDataListLength, mainEcgDecimalList.length)
    //     .toList();

    // sgFilteredEcg = Array(result);

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

    // peaksArrayEcg = findPeaks(filterOPEcg,
    //     // Array(filterOPEcg.getRange(0, filterOPEcg.length).toList()),
    //     threshold: _threshold);
    peaksPositionsEcgArray.clear();
    peaksArrayEcg.clear();
    for (int f = 2000; f < filterOPEcg.length; f++) {
      if (f - 1 > 0 && f + 1 < filterOPEcg.length) {
        printLog(
            "ffffff gh ${filterOPEcg[f]}   ${0.45 * (filterOPEcg.getRange(filterOPEcg.length - 2000, filterOPEcg.length)).reduce(math.max)}");

        if (filterOPEcg[f] > filterOPEcg[f - 1] &&
            filterOPEcg[f] >= filterOPEcg[f + 1] &&
            filterOPEcg[f] >
                0.45 * (filterOPEcg.getRange(filterOPEcg.length - 2000, filterOPEcg.length)).reduce(math.max)) {
          peaksArrayEcg.add(filterOPEcg[f]);
          peaksPositionsEcgArray.add(f);
        }
      }
    }

    printLog("Peaks Length " + peaksArrayEcg.length.toString());
    printLog("Peaks Ecg" + peaksArrayEcg.toString());
    printLog("Peaks_position Array " + peaksPositionsEcgArray.toString());

    // for (int i = 0; i < peaksArrayEcg.length; i++) {
    //   printLog("AAA ${i.toString()} " + peaksArrayEcg[i].length.toString());
    //   if (i == 0) {
    //     for (int j = 0; j < peaksArrayEcg[i].length; j++) {
    //       if (j + 1 < (peaksArrayEcg[i].length)) {
    //         printLog("jjjj ${j} ${peaksArrayEcg[i][j + 1]} ${peaksArrayEcg[i][j]}");

    //         var interval = ((peaksArrayEcg[i][j + 1] - peaksArrayEcg[i][j]) / 200);
    //         printLog("jjjj interval ${interval}");

    //         totalOfPeaksEcg += ((peaksArrayEcg[i][j + 1] - peaksArrayEcg[i][j]) / 200);

    //       }
    //     }
    //   }
    // }

    //HeartRateList.clear();
    rrIntervalList.clear();

    for (int j = 0; j < peaksPositionsEcgArray.length; j++) {
      if (j + 1 < peaksPositionsEcgArray.length) {
        printLog("jjjj $j ${peaksPositionsEcgArray[j + 1]} ${peaksPositionsEcgArray[j]}");
        rrIntervalList.add((peaksPositionsEcgArray[j + 1] - peaksPositionsEcgArray[j]));
        /* double interval = double.parse(
            ((peaksPositionsEcgArray[j + 1] - peaksPositionsEcgArray[j]) / 200)
                .toStringAsFixed(2));
        rrIntervalList.add(interval);
        double speed = double.parse((60 / (interval * 100)).toStringAsFixed(2));
        HeartRateList.add(speed);
        printLog("jjjj interval ${interval}");*/
        //  if (interval < 1.2) {
        totalOfPeaksEcg += ((peaksPositionsEcgArray[j + 1] - peaksPositionsEcgArray[j]) / 200);
        // }

        // totalOfPeaksEcg += ((peaksArrayEcg[i][j + 1] - peaksArrayEcg[i][j]) / 200);
      }
    }
    print("rrIntervalList $rrIntervalList");
    // print("HeartRateList $HeartRateList");

    if (rrIntervalList == []) {
      rrIntervalList.add(0);
    }
    arrhythmia_type = GetArrthmiaType(rrIntervalList);

    printLog("totalOfPeaksEcg  " +
        totalOfPeaksEcg.toString() +
        " avg " +
        (totalOfPeaksEcg / (peaksPositionsEcgArray.length)).toString());
    double avgPeak = (totalOfPeaksEcg / (peaksPositionsEcgArray.length));
    // if (avgPeak.isInfinite || avgPeak.isNaN) {
    //   avgPeak = 1;
    // }
    heartRate = (60 / avgPeak).round();
    // notifyListeners();
  }

  void countPpgHeartRate() {
    sgFilteredPpg = Array([]);
    filterOPPpg = Array([]);

    peaksArrayPpg = [];
    totalOfPeaksPpg = 0;

    var fs = 100;
    var nyq = 0.5 * fs; // design filter
    var cutOff = 20;
    var normalFc = cutOff / nyq;
    var numtaps = 127;
    // double _threshold = 0;

    var b = firwin(numtaps, Array([normalFc]));
    if (mainPpgDecimalList.length > filterDataListLength) {
      sgFilteredPpg = lfilter(
          b,
          Array([1.0]),
          Array(mainPpgDecimalList
              .getRange(mainPpgDecimalList.length - filterDataListLength, mainPpgDecimalList.length)
              .toList())); // filter the signal
    } else {
      sgFilteredPpg = lfilter(b, Array([1.0]), Array(mainPpgDecimalList)); // filter the signal
    }

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
    // showSnackBar(filterOPPpg.toString());

    // // _threshold = ((filterOPPpg).reduce(math.max)) * 0.6;
    // _threshold = 500;

    // printLog("CCC _thresholdPpg max ${(filterOPPpg).reduce(math.max)} hhh " + _threshold.toString());
    // // peaksArrayPpg = findPeaks(filterOPPpg,
    // //     // Array(filterOPPpg.getRange(filterOPPpg.length - noiseLength, filterOPPpg.length).toList()),
    // //     threshold: _threshold);

    // printLog("Peaks Ppg Length " + peaksArrayPpg.length.toString());
    // printLog("Peaks Ppg" + peaksArrayPpg.toString());

    // // List<dynamic> tempPeakList = [];
    // int index = 0;
    // print("peaksArray.length ${peaksArrayEcg[index].length} ${peaksArrayPpg[index].length}");

    peaksPositionsPpgArray.clear();
    peaksArrayPpg.clear();
    for (int f = 2000; f < filterOPPpg.length; f++) {
      if (f - 1 > 0 && f + 1 < filterOPPpg.length) {
        // showSnackBar(
        //     "ffffff ${filterOPPpg[f]}   ${0.45 * (filterOPPpg.getRange(filterOPPpg.length - 2000, filterOPPpg.length)).reduce(math.max)}");

        printLog(
            "ffffff gh ${filterOPPpg[f]}   ${0.45 * (filterOPPpg.getRange(filterOPPpg.length - 2000, filterOPPpg.length)).reduce(math.max)}");

        if (filterOPPpg[f] > filterOPPpg[f - 1] &&
            filterOPPpg[f] >= filterOPPpg[f + 1] &&
            filterOPPpg[f] >
                0.45 * (filterOPPpg.getRange(filterOPPpg.length - 2000, filterOPPpg.length)).reduce(math.max)) {
          // showSnackBar("filterOPPpg for loop array inside if condition");

          peaksArrayPpg.add(filterOPPpg[f]);
          peaksPositionsPpgArray.add(f);
        }
      }
    }

    printLog("Peaks_position Array " + peaksPositionsPpgArray.toString());
    // showSnackBar("peaksPositionsPpgArray_length ${peaksPositionsPpgArray.length.toString()}");

    // if (peaksArrayEcg[index].length < peaksArrayPpg[index].length) {
    //   tempPeakList = peaksArrayEcg[index];
    // } else {
    //   tempPeakList = peaksArrayPpg[index];
    // }
    pttArray.clear();
    prv.clear();
    hrv.clear();

    for (int p = 0; p < peaksPositionsPpgArray.length; p++) {
      if (p + 1 < peaksPositionsPpgArray.length) {
        if (((60 * 200 / (peaksPositionsPpgArray[p + 1] - peaksPositionsPpgArray[p]) < 500)) &&
            ((60 * 200 / (peaksPositionsPpgArray[p + 1] - peaksPositionsPpgArray[p]) > 0))) {
          prv.add((60 * 200 / (peaksPositionsPpgArray[p + 1] - peaksPositionsPpgArray[p])));
        }
      }

      print("uuu ecg");

      for (int e = 0; e < peaksPositionsEcgArray.length; e++) {
        print("uuu ecg ${e.toString()} ${peaksPositionsEcgArray[e].toString()}");
        print("uuu ppg ${p.toString()} ${peaksPositionsPpgArray[p].toString()}");
        if (e + 1 < peaksPositionsEcgArray.length) {
          if (((60 * 200 / (peaksPositionsEcgArray[e + 1] - peaksPositionsEcgArray[e]) < 500)) &&
              ((60 * 200 / (peaksPositionsEcgArray[e + 1] - peaksPositionsEcgArray[e]) > 0))) {
            hrv.add((60 * 200 / (peaksPositionsEcgArray[e + 1] - peaksPositionsEcgArray[e])));
          }
        }

        if (peaksPositionsEcgArray[e] < peaksPositionsPpgArray[p]) {
          double diff = ((peaksPositionsPpgArray[p] - peaksPositionsEcgArray[e]) / 200);
          //pttArray.add(diff);
          if (diff <= 0.8) {
            pttArray.add(diff);
            totalOfPeaksPpg += ((peaksPositionsPpgArray[p] - peaksPositionsEcgArray[e]) / 200);
          }
        }
      }
    }

    avgPrv = mean(Array(prv.toList()));
    if (avgPrv.isNaN || avgPrv.isInfinite) {
      avgPrv = 0;
    }
    // showSnackBar("avgPrv ${avgPrv.toString()}");

    avgHrv = mean(Array(hrv.toList()));
    if (avgHrv.isNaN || avgHrv.isInfinite) {
      avgHrv = 0;
    }
    //showSnackBar("avgHrv ${avgHrv.toString()}");

    printLog("rrrr prv:  ${prv.toList()} avg: ${avgPrv.toString()}");
    printLog("rrrr hrv:  ${hrv.toList()} array: ${avgHrv.toString()}");

    printLog("ggg pttArray_length:  ${pttArray.length} array: ${pttArray.toString()}");

    avgPTT = (totalOfPeaksPpg / (pttArray.length));

    if (avgPTT.isNaN || avgPTT.isInfinite) {
      avgPTT = 0;
    }
    //  showSnackBar("totalOfPeaksPpg  " + totalOfPeaksPpg.toString() + " avg " + avgPTT.toString());

    printLog("ggg totalOfPeaksPpg  " + totalOfPeaksPpg.toString() + " avg " + avgPTT.toString());

    // dBp = 134.802365863 - 83.006119783168 * avgPTT;
    // dDbp = 99.606825109447 - 96.651802662872 * avgPTT;
    dBp = 145.802365863 - 83.006119783168 * avgPTT;
    dDbp = 110.606825109447 - 96.651802662872 * avgPTT;

    heartRatePPG = "BP: ${dBp.round().toString()} $bpUnit\n DBP: ${dDbp.round().toString()} $bpUnit";
    // heartRatePPG = (60 / (totalOfPeaksPpg / (peaksArrayPpg[0].length))).round();
    // heartRatePPG = ((60 * peaksArrayPpg[0].length) / 2.5).round();

    printLog("heartRatePPG :  " + heartRatePPG.toString());
  }

  Future<ArrhythmiaType> GetArrthmiaType(List<int> rrHeartList) async {
    print("GetArrthmiaType");
    final response = await http.post(
      Uri.parse(fastAPI + '/prediction'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'data': rrHeartList}),
    );
    //jsonEncode(<String, List<int>>{
    //         'RR': rrHeartList,
    //       }),
    print("send response ${response.statusCode}");
    if (response.statusCode == 200) {
      print("success ArrhythmiaType");
      return ArrhythmiaType.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      throw Exception('Failed to create ArrthmiaType.');
    }
  }

  Future<TrainModel> TrainModelForType() async {
    final response = await http.get(
      Uri.parse(fastAPI + '/train_model'),
    );

    if (response.statusCode == 200) {
      print("success TrainModel");
      return TrainModel.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      throw Exception('Failed to create TrainModel.');
    }
  }
}
