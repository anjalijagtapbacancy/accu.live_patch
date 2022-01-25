import 'dart:async';

import 'dart:isolate';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';
import 'package:scidart/scidart.dart';
import 'package:scidart/numdart.dart';
import 'dart:math' as math;
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:collection/collection.dart';

class ProviderGraphData with ChangeNotifier, Constant {
  List<BluetoothDevice> devicesList = [];
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;
  bool isFirst = true;
  String? arrhythmia_type;

  Location location = new Location();
  var classifier, createClassifier;
  bool isLocServiceEnabled = false;
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
  int index = 0;
  bool isecgppgOrSpo2 = false;
  int tabLength = 3;
  int ecgDataLength = 0;
  int ppgDataLength = 0;
  int tabSelectedIndex = 0;
  double SumRt = 0;
  double AvgRt = 0;
  int BpFromRt = 0;
  List<dynamic> data = [];

  //List<double> rrIntervalList = [];
  List<dynamic> rrInterval = [];
  List<double> rtIntervalList = [];
  List<double> IntervalList = [];
  List<double> savedIntervalList = [];

  List<int> rrIntervalList1 = [];
  List<double> IntervalList1 = [];

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
  List<dynamic> R_peaksArrayEcg = [];
  List<dynamic> S_peaksArrayEcg = [];
  List<dynamic> T_peaksArrayEcg = [];
  double totalOfPeaksEcg = 0;

  Array sgFilteredPpg = Array([]);
  Array filterOPPpg = Array([]);
  List<dynamic> peaksArrayPpg = [];
  double totalOfPeaksPpg = 0;

  Array sgFilteredEcg1 = Array([]);
  Array filterOPEcg1 = Array([]);
  List<dynamic> peaksArrayEcg1 = [];
  double totalOfPeaksEcg1 = 0;

  double stepCount = 0;
  int heartRate = 0;
  List<double> pttArray = [];
  List<int> R_peaksPositionsEcgArray = [];
  List<int> S_peaksPositionsEcgArray = [];
  List<int> T_peaksPositionsEcgArray = [];
  List<int> peaksPositionsEcgArray1 = [];
  List<int> peaksPositionsPpgArray = [];

  double avgPTT = 0;
  double dBp = 0;
  double dDbp = 0;
  double PP = 0;
  double MAP = 0;
  double CO = 0;
  double SV = 0;
  double avgPeak = 0;
  bool isecgSelected = false,
      isppgSelected = false,
      isecgppgSelected = false,
      isspo2Selected = false;

  // static double avgPrv1=0,avgHrv1= 0;
  // static double avgPTT1 = 0;
  // static double dBp1 = 0;
  // static double dDbp1 = 0;

  // static Future<ArrhythmiaType>? arrhythmia_type1;
  // static int heartRate1 = 0;

  int noiseLength = 0;
  int frameLength = 11;

  List<double> hrv = [];
  double avgHrv = 0;
  List<double> prv = [];
  double avgPrv = 0;

  static late Isolate RT_Interval, count_ecg_heartrate, count_ppg_heartrate;

  // SgFilter filter = new SgFilter(3, frameLength);

  clearProviderGraphData() {
    BpFromRt = 0;
    avgHrv = 0;
    avgPrv = 0;
    dBp = 0;
    dDbp = 0;
    PP = 0;
    MAP = 0;
    CO = 0;
    SV = 0;
    avgPeak = 0;
    arrhythmia_type = null;
    tabSelectedIndex = 0;
    devicesList.clear();
    isLoading = false;
    services!.clear();
    connectedDevice = null;
    readValues = new Map<Guid, List<int>>();
    isServiceStarted = false;
    stepCount = 0;
    spo2Val = 0;
    avgPTT = 0;
    heartRate = 0;
    savedEcgLocalDataList.clear();
    mainEcgSpotsListData.clear();
    tempEcgSpotsListData.clear();
    mainEcgHexList.clear();
    mainEcgDecimalList.clear();
    tempEcgHexList.clear();
    tempEcgDecimalList.clear();
    IntervalList.clear();
    IntervalList1.clear();

    savedIntervalList.clear();
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
  void setIndex(int Index) {
    index = Index;
    notifyListeners();
  }

  setIsecgppgOrSpo2(bool value) {
    isecgppgOrSpo2 = value;
    notifyListeners();
  }

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

  setisFirst(bool value) {
    isFirst = value;
    //notifyListeners();
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

  setecgSelected() {
    isecgSelected = !isecgSelected;
    notifyListeners();
  }
  setppgSelected() {
    isppgSelected = !isppgSelected;
    notifyListeners();
  }
  setecgppgSelected() {
    isecgppgSelected = !isecgppgSelected;
    notifyListeners();
  }
  setspo2Selected() {
    isspo2Selected = !isspo2Selected;
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

  setConnectedDevice(BluetoothDevice device, BuildContext context,
      List<BluetoothService> service) async {
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
    try {
      for (int k = 0; k < tempEcgDecimalList.length; k++) {
        // if ((mainEcgSpotsListData.length) + 1 / periodicTimeInSec == 0) {

        mainEcgSpotsListData.add(FlSpot(
            double.tryParse(((mainEcgDecimalList.length + k)).toString()) ?? 0,
            tempEcgDecimalList[k]));
      }

      for (int k = 0; k < tempPpgDecimalList.length; k++) {
        mainPpgSpotsListData.add(FlSpot(
            double.tryParse(((mainPpgDecimalList.length + k)).toString()) ?? 0,
            tempPpgDecimalList[k]));
      }
      if (isEnabled) {
        periodicTask();
      }

      if (mainEcgSpotsListData.length > yAxisGraphData) {
        //print("if mainEcgSpotsListData.length==${mainEcgSpotsListData.length}");
        tempEcgSpotsListData = mainEcgSpotsListData
            .getRange(mainEcgSpotsListData.length - yAxisGraphData,
                mainEcgSpotsListData.length)
            .toList();
      } else {
        //print("else mainEcgSpotsListData.length==${mainEcgSpotsListData.length}");
        // tempEcgSpotsListData = mainEcgSpotsListData
        //     .getRange(
        //         mainEcgSpotsListData.length - 200, mainEcgSpotsListData.length)
        //     .toList();
        tempEcgSpotsListData = mainEcgSpotsListData.toList();
      }

      if (mainPpgSpotsListData.length > yAxisGraphData) {
        tempPpgSpotsListData = mainPpgSpotsListData
            .getRange(mainPpgSpotsListData.length - yAxisGraphData,
                mainPpgSpotsListData.length)
            .toList();
      } else {
        // tempPpgSpotsListData = mainPpgSpotsListData
        //     .getRange(
        //         mainPpgSpotsListData.length - 200, mainPpgSpotsListData.length)
        //     .toList();
        tempPpgSpotsListData = mainPpgSpotsListData.toList();
      }
    } catch (Exception) {
      print("Exception ${e.toString()}");
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

    List<double> localIntervalList = box.get("rrIntervalList") ?? [];
    localIntervalList.addAll(IntervalList);
    await box.put("rrIntervalList", localIntervalList);

    savedIntervalList = box.get("rrIntervalList") ?? [];
    savedEcgLocalDataList = box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = box.get("ppg_graph_data") ?? [];
    printLog(
        "local Data saved!.... ecg: ${savedEcgLocalDataList.length} ppg: ${savedPpgLocalDataList.length} rrIntervalList: ${savedIntervalList.length}");
  }

  getStoredLocalData() async {
    var box = await Hive.openBox<List<double>>('graph_data');

    savedIntervalList = box.get("rrIntervalList") ?? [];
    savedEcgLocalDataList = box.get("ecg_graph_data") ?? [];
    savedPpgLocalDataList = box.get("ppg_graph_data") ?? [];
  }

  clearStoreDataToLocal() async {
    //stepCount = 0;
    BpFromRt = 0;
    arrhythmia_type = null;
    avgHrv = 0;
    avgPrv = 0;
    dBp = 0;
    dDbp = 0;
    PP = 0;
    MAP = 0;
    CO = 0;
    SV = 0;
    avgPeak = 0;
    spo2Val = 0;
    avgPTT = 0;
    heartRate = 0;
    savedEcgLocalDataList.clear();
    mainEcgSpotsListData.clear();
    tempEcgSpotsListData.clear();
    mainEcgHexList.clear();
    mainEcgDecimalList.clear();
    tempEcgHexList.clear();
    tempEcgDecimalList.clear();
    IntervalList.clear();

    savedIntervalList.clear();
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
    // print("getSpo2Data valueList ${valueList!.length} ${valueList.toList()}");
    print("getSpo2Data");
    if (valueList!.length == 2) {
      /*   for (int i = 0; i < valueList.length; i++) {
        print(valueList[i].toRadixString(16).padLeft(2, '0').toString());
      }
*/
      String strHex = valueList[1].toRadixString(16).padLeft(2, '0') +
          valueList[0].toRadixString(16).padLeft(2, '0');
      //print("strHex $strHex");

      spo2Val = (double.parse(
              int.parse(strHex, radix: 16).toString().padLeft(1, '0'))) /
          100;
      if (spo2Val > 100) {
        spo2Val = 100.0;
      }
      print("spo2Val read ${spo2Val.toString()}");
    }
    notifyListeners();
  }

  void generateGraphValuesList(List<int>? valueList) async {
    if (valueList != null && valueList.length > 0) {
      //printLog("valueList ${valueList.toList()}");
      printLog("valueList.lengh ${valueList.length}");
      List<int>? stepCountList = [
        valueList[valueList.length - 2],
        valueList[valueList.length - 1]
      ];

      List<String> stepCountHexList = [
        stepCountList[0].toRadixString(16).padLeft(2, '0'),
        stepCountList[1].toRadixString(16).padLeft(2, '0')
      ];

      String strStepHex = stepCountHexList[1] + stepCountHexList[0];
      //print("sss valueList  list ${valueList.length.toString()}");

      stepCount = double.parse(int.parse(strStepHex, radix: 16).toString());
      //printLog("stepCount ${stepCount.toString()}");

      for (int i = 0; i < (valueList.length - 2); i++) {
        if (i < ((valueList.length - 2) / 2)) {
          mainEcgHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
        } else {
          mainPpgHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
        }
      }
      print("ecg hex list ${mainEcgHexList.length.toString()}");
      print("ppg hex list ${mainPpgHexList.length.toString()}");

      if (mainEcgHexList.length > (yAxisGraphData * 2) &&
          mainPpgHexList.length > (yAxisGraphData * 2)) {
        tempEcgHexList = mainEcgHexList
            .getRange(mainEcgHexList.length - (yAxisGraphData * 2),
                mainEcgHexList.length)
            .toList();
        tempPpgHexList = mainPpgHexList
            .getRange(mainPpgHexList.length - (yAxisGraphData * 2),
                mainPpgHexList.length)
            .toList();
      } else {
        tempEcgHexList = mainEcgHexList.toList();
        tempPpgHexList = mainPpgHexList.toList();
      }

      mainEcgDecimalList.clear();
      for (int h = 0; h < mainEcgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = mainEcgHexList[h + 1] + mainEcgHexList[h];
          mainEcgDecimalList
              .add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }
      // if (mainEcgDecimalList.length >= frameLength) {
      //   mainEcgDecimalList = filter.smooth(mainEcgDecimalList);
      // }

      mainPpgDecimalList.clear();
      for (int h = 0; h < mainPpgHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = mainPpgHexList[h + 1] + mainPpgHexList[h];
          mainPpgDecimalList
              .add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }
      // if (mainPpgDecimalList.length >= frameLength) {
      //   mainPpgDecimalList = filter.smooth(mainPpgDecimalList);
      // }
      // if (mainEcgDecimalList.length <= 100) {
      //   yAxisGraphData = 100;
      // } else if (mainEcgDecimalList.length > 100 ||
      //     mainEcgDecimalList.length <= 200) {
      //   yAxisGraphData = 200;
      // } else if (mainEcgDecimalList.length > 200 ||
      //     mainEcgDecimalList.length <= 400) {
      //   yAxisGraphData = 400;
      // } else if (mainEcgDecimalList.length > 400 ||
      //     mainEcgDecimalList.length <= 600) {
      //   yAxisGraphData = 600;
      // } else if (mainEcgDecimalList.length > 600 ||
      //     mainEcgDecimalList.length <= 800) {
      //   yAxisGraphData = 800;
      // } else {
      //   yAxisGraphData = 1000;
      // }
      //
      if (mainEcgDecimalList.length > yAxisGraphData) {
        tempEcgDecimalList = mainEcgDecimalList
            .getRange(mainEcgDecimalList.length - yAxisGraphData,
                mainEcgDecimalList.length)
            .toList();
      } else {
        tempEcgDecimalList = mainEcgDecimalList.toList();
      }

      if (mainPpgDecimalList.length > yAxisGraphData) {
        tempPpgDecimalList = mainPpgDecimalList
            .getRange(mainPpgDecimalList.length - yAxisGraphData,
                mainPpgDecimalList.length)
            .toList();
      } else {
        tempPpgDecimalList = mainPpgDecimalList.toList();
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

  void periodicTask() async {
    try {
      if (mainEcgHexList.length > 0 &&
          (mainEcgHexList.length) % filterDataListLength1 == 0) {
        PeriodicHeartRate();
      }
      if (mainEcgHexList.length > 0 &&
          (mainEcgHexList.length) % periodicTimeInSec == 0) {
        //count_ecg_heartrate = await Isolate.spawn(countEcgHeartRate,mainEcgDecimalList);
        //count_ecg_heartrate.kill(priority: Isolate.immediate);
        countEcgHeartRate();
        countPpgHeartRate();
        // heartRate=heartRate1;
        //  count_ppg_heartrate = await Isolate.spawn(countPpgHeartRate,mainPpgDecimalList);
        //print("heartRate1 ${ProviderGraphData.heartRate1} ,count_ecg_heartrate ${count_ecg_heartrate} ");
        // avgPTT=avgPTT1;
        // avgHrv=avgHrv1;
        // avgPrv=avgPrv1;

        // arrhythmia_type=arrhythmia_type1;
        // dBp=dBp1;
        // dDbp=dDbp1;
      }
      // notifyListeners();
      // else {
      //   printLog(
      //       "periodicTask elsee  ecg ............... ${mainEcgHexList.length}");
      // }
    } catch (Exception) {
      printLog("periodicTask Exception ${Exception.toString()}");
    }
  }

  void PeriodicHeartRate() {
    try {
      sgFilteredEcg1 = Array([]);
      filterOPEcg1 = Array([]);

      peaksArrayEcg1 = [];
      totalOfPeaksEcg1 = 0;

      var fs = 100;
      var nyq = 0.5 * fs; // design filter
      var cutOff = 20;
      var normalFc = cutOff / nyq;
      var numtaps = 127;

      var b = firwin(numtaps, Array([normalFc]));
      if (mainEcgDecimalList.length > filterDataListLength1) {
        sgFilteredEcg1 = lfilter(
            b,
            Array([1.0]),
            Array(mainEcgDecimalList
                .getRange(mainEcgDecimalList.length - filterDataListLength1,
                    mainEcgDecimalList.length)
                .toList())); // filter the signal
        // printLog(
        //     "getRange...1 ${mainEcgDecimalList.length - filterDataListLength1} ${mainEcgDecimalList.length}");
      } //  else {
      //   filterOPEcg1 = lfilter(
      //       b, Array([1.0]), Array(mainEcgDecimalList)); // filter the signal
      // }

      // List<double> result = mainEcgDecimalList
      //     .getRange(mainEcgDecimalList.length - filterDataListLength, mainEcgDecimalList.length)
      //     .toList();

      // sgFilteredEcg = Array(result);

      //final filter output
      var fs1 = 25;
      var nyq1 = 0.5 * fs1; // design filter
      var cutOff1 = 0.5;
      var normalFc1 = cutOff1 / nyq1;
      var numtaps1 = 685;
      var passZero = 'highpass';

      var b1 = firwin(numtaps1, Array([normalFc1]), pass_zero: passZero);
      filterOPEcg1 =
          lfilter(b1, Array([1.0]), sgFilteredEcg1); // filter the signal

      peaksPositionsEcgArray1.clear();
      peaksArrayEcg1.clear();
      //printLog("filterOPEcg1.length1 ${filterOPEcg1.length}");
      //printLog("filterOPEcg1 ${filterOPEcg1.toList()}");
      for (int f = 500; f < filterOPEcg1.length; f++) {
        if (f - 1 > 0 && f + 1 < filterOPEcg1.length) {
          //printLog("ffffff gh1 ${filterOPEcg1[f]}   ${0.45 * (filterOPEcg1.getRange(filterOPEcg1.length - filterDataListLength1, filterOPEcg1.length)).reduce(math.max)}");

          if (filterOPEcg1[f] > filterOPEcg1[f - 1] &&
              filterOPEcg1[f] >= filterOPEcg1[f + 1] &&
              filterOPEcg1[f] >
                  0.45 *
                      (filterOPEcg1.getRange(
                              filterOPEcg1.length - 1100, filterOPEcg1.length))
                          .reduce(math.max)) {
            peaksArrayEcg1.add(filterOPEcg1[f]);
            peaksPositionsEcgArray1.add(f);
          }
        }
      }

      //printLog("Peaks Length1 " + peaksArrayEcg1.length.toString());
      //printLog("Peaks Ecg1" + peaksArrayEcg1.toString());
      //printLog("Peaks_position Array1 " + peaksPositionsEcgArray1.toString());

      rrIntervalList1.clear();

      for (int j = 0; j < peaksPositionsEcgArray1.length; j++) {
        if (j + 1 < peaksPositionsEcgArray1.length) {
          // printLog("jjjj1 $j ${peaksPositionsEcgArray1[j + 1]} ${peaksPositionsEcgArray1[j]}");
          rrIntervalList1.add(
              (peaksPositionsEcgArray1[j + 1] - peaksPositionsEcgArray1[j]));
          /* double interval = double.parse(
            ((peaksPositionsEcgArray[j + 1] - peaksPositionsEcgArray[j]) / 200)
                .toStringAsFixed(2));
        rrIntervalList.add(interval);
        double speed = double.parse((60 / (interval * 100)).toStringAsFixed(2));
        HeartRateList.add(speed);
        printLog("jjjj interval ${interval}");*/
          //  if (interval < 1.2) {
          totalOfPeaksEcg1 +=
              ((peaksPositionsEcgArray1[j + 1] - peaksPositionsEcgArray1[j]) /
                  200);
          IntervalList1.add(totalOfPeaksEcg1);
        }
      }
      //printLog("rrIntervalList1 $rrIntervalList1");
      // print("HeartRateList $HeartRateList");

      if (rrIntervalList1 == []) {
        rrIntervalList1.add(0);
      }

      printLog("totalOfPeaksEcg1  " +
          totalOfPeaksEcg1.toString() +
          " avg1 " +
          (totalOfPeaksEcg1 / (peaksPositionsEcgArray1.length)).toString());
      double avgPeak = (totalOfPeaksEcg1 / (peaksPositionsEcgArray1.length));
      if (avgPeak.isInfinite || avgPeak.isNaN) {
        heartRate = 0;
      } else {
        if ((60 / avgPeak).round() > 200) {
          heartRate = 200;
        } else {
          heartRate = (60 / avgPeak).round();
        }
      }
      print("heartRate $heartRate");
      // notifyListeners();
    } catch (Exception) {
      print("Exception ecg ${Exception.toString()}");
    }
  }

  void countEcgHeartRate() {
    try {
      sgFilteredEcg = Array([]);
      filterOPEcg = Array([]);

      R_peaksArrayEcg = [];
      totalOfPeaksEcg = 0;

      var fs = 100;
      var nyq = 0.5 * fs; // design filter
      var cutOff = 20;
      var normalFc = cutOff / nyq;
      var numtaps = 127;

      var b = firwin(numtaps, Array([normalFc]));
      if (mainEcgDecimalList.length > Constant.filterDataListLength) {
        sgFilteredEcg = lfilter(
            b,
            Array([1.0]),
            Array(mainEcgDecimalList
                .getRange(
                    mainEcgDecimalList.length - Constant.filterDataListLength,
                    mainEcgDecimalList.length)
                .toList())); // filter the signal
        print(
            "getRange... ${mainEcgDecimalList.length - Constant.filterDataListLength} ${mainEcgDecimalList.length}");
      } else {
        sgFilteredEcg = lfilter(
            b, Array([1.0]), Array(mainEcgDecimalList)); // filter the signal
      }

      // List<double> result = mainEcgDecimalList
      //     .getRange(mainEcgDecimalList.length - filterDataListLength, mainEcgDecimalList.length)
      //     .toList();

      // sgFilteredEcg = Array(result);

      //final filter output
      var fs1 = 100;
      var nyq1 = 0.5 * fs1; // design filter
      var cutOff1 = 0.5;
      var normalFc1 = cutOff1 / nyq1;
      var numtaps1 = 2747;
      var passZero = 'highpass';
      var b1 = firwin(numtaps1, Array([normalFc1]), pass_zero: passZero);
      filterOPEcg =
          lfilter(b1, Array([1.0]), sgFilteredEcg); // filter the signal

      // printLog("CCC sgFilteredEcg " +
      //     sgFilteredEcg.runtimeType.toString() +
      //     " " +
      //     sgFilteredEcg.length.toString());
      //
      // printLog("CCC filterOPEcg " +
      //     filterOPEcg.runtimeType.toString() +
      //     " " +
      //     filterOPEcg.length.toString());
      // printLog("CCC " + filterOPEcg.toString());
      // _threshold = ((filterOPEcg).reduce(math.max)) * 0.28;
      // printLog("CCC max ${(filterOPEcg).reduce(math.max)} _threshold " +
      //     _threshold.toString());

      // R_peaksArrayEcg = findPeaks(filterOPEcg,
      //     // Array(filterOPEcg.getRange(0, filterOPEcg.length).toList()),
      //     threshold: _threshold);
      R_peaksPositionsEcgArray.clear();
      R_peaksArrayEcg.clear();
      for (int f = 2000; f < filterOPEcg.length; f++) {
        if (f - 1 > 0 && f + 1 < filterOPEcg.length) {
          // printLog("ffffff gh ${filterOPEcg[f]}   ${0.45 * (filterOPEcg.getRange(filterOPEcg.length - 2000, filterOPEcg.length)).reduce(math.max)}");

          if (filterOPEcg[f] > filterOPEcg[f - 1] &&
              filterOPEcg[f] >= filterOPEcg[f + 1] &&
              filterOPEcg[f] >
                  0.45 *
                      (filterOPEcg.getRange(
                              filterOPEcg.length - 2000, filterOPEcg.length))
                          .reduce(math.max)) {
            R_peaksArrayEcg.add(filterOPEcg[f]);
            R_peaksPositionsEcgArray.add(f);
            if (filterOPEcg[f] < filterOPEcg[f - 1] &&
                filterOPEcg[f] <= filterOPEcg[f + 1] &&
                filterOPEcg[f] <
                    0.60 *
                        (filterOPEcg.getRange(
                                filterOPEcg.length - 2000, filterOPEcg.length))
                            .reduce(math.min)) {
              S_peaksArrayEcg.add(filterOPEcg[f]);
              S_peaksPositionsEcgArray.add(f);
            }
          }
        }
      }

      //print("Peaks Length " + R_peaksArrayEcg.length.toString());
      //print("Peaks Ecg" + R_peaksArrayEcg.toString());
      //print("Peaks_position Array " + R_peaksPositionsEcgArray.toString());

      // for (int i = 0; i < R_peaksArrayEcg.length; i++) {
      //   printLog("AAA ${i.toString()} " + R_peaksArrayEcg[i].length.toString());
      //   if (i == 0) {
      //     for (int j = 0; j < R_peaksArrayEcg[i].length; j++) {
      //       if (j + 1 < (R_peaksArrayEcg[i].length)) {
      //         printLog("jjjj ${j} ${R_peaksArrayEcg[i][j + 1]} ${R_peaksArrayEcg[i][j]}");

      //         var interval = ((R_peaksArrayEcg[i][j + 1] - R_peaksArrayEcg[i][j]) / 200);
      //         printLog("jjjj interval ${interval}");

      //         totalOfPeaksEcg += ((R_peaksArrayEcg[i][j + 1] - R_peaksArrayEcg[i][j]) / 200);

      //       }
      //     }
      //   }
      // }

      //HeartRateList.clear();
      //rrIntervalList.clear();
      rrInterval.clear();
      data.clear();

      for (int j = 0; j < R_peaksPositionsEcgArray.length; j++) {
        if (j + 1 < R_peaksPositionsEcgArray.length) {
          //printLog("jjjj $j ${R_peaksPositionsEcgArray[j + 1]} ${R_peaksPositionsEcgArray[j]}");
          // rrIntervalList.add(
          //     (R_peaksPositionsEcgArray[j + 1] - R_peaksPositionsEcgArray[j]) /
          //         200);
          /* double interval = double.parse(
            ((R_peaksPositionsEcgArray[j + 1] - R_peaksPositionsEcgArray[j]) / 200)
                .toStringAsFixed(2));
        rrIntervalList.add(interval);
        double speed = double.parse((60 / (interval * 100)).toStringAsFixed(2));
        HeartRateList.add(speed);
        printLog("jjjj interval ${interval}");*/
          //  if (interval < 1.2) {
          totalOfPeaksEcg +=
              ((R_peaksPositionsEcgArray[j + 1] - R_peaksPositionsEcgArray[j]) /
                  200);
          IntervalList.add(totalOfPeaksEcg);
          // }

          // totalOfPeaksEcg += ((R_peaksArrayEcg[i][j + 1] - R_peaksArrayEcg[i][j]) / 200);
        }
      }
      //print("rrIntervalList $rrIntervalList");

      // if (rrIntervalList.isEmpty) {
      //   rrIntervalList.add(0);
      // }
      // data = [rrIntervalList.average];
      // print("data $data");
      // rrInterval.add(data);
      // //print("rrInterval ${rrInterval.toList()}");
      // if (rrInterval.isNotEmpty) {
      //   Prediction();
      // }
      //arrhythmia_type = GetArrthmiaType(rrIntervalList);

      print("totalOfPeaksEcg  " +
          totalOfPeaksEcg.toString() +
          " avg " +
          (totalOfPeaksEcg / (R_peaksPositionsEcgArray.length)).toString());
      avgPeak = (totalOfPeaksEcg / (R_peaksPositionsEcgArray.length));
      if (avgPeak.isInfinite || avgPeak.isNaN) {
        heartRate = 0;
        avgPeak = 0;
      } else {
        if ((60 / avgPeak).round() > 200) {
          heartRate = 200;
        } else {
          heartRate = (60 / avgPeak).round();
        }
      }
      print("heartRate $heartRate");
      rrInterval.add([avgPeak]);
      if (rrInterval.isNotEmpty) {
        Prediction();
      }
      //heartRate=heartRate1;
      // Constant.providerGraphData.arrhythmia_type=arrhythmia_type;
      //print("before RtInterval");
      // if (RT_Interval != null) {
      //   stopIsolate();
      //   print("kill interval 3");
      // }
      //print("R_peaksPositionsEcgArray ${R_peaksPositionsEcgArray.length}");
      //startIsolate();
      RTInterval(R_peaksPositionsEcgArray);
      //print("start RtInterval");
      notifyListeners();
    } catch (Exception) {
      print("Exception ecg ${Exception.toString()}");
    }
  }

  Future<void> startIsolate() async {
    printLog("startIsolate");
    ReceivePort receivePort = ReceivePort();
    RT_Interval = await Isolate.spawn(RTInterval, R_peaksPositionsEcgArray);
    //printLog("stop");
    // stopIsolate();
  }

  void RTInterval(List<int> R_peaksPositionsEcgArray) {
    //print("in RtInterval");

    //print("R_peaksPositionsEcgArray1 ${R_peaksPositionsEcgArray.length}");
    //print("R_peaksPositionsEcgArray1 ${R_peaksPositionsEcgArray.toList()}");
    //print("filterOPEcg ${filterOPEcg.toList()}");
    T_peaksArrayEcg.clear();
    T_peaksPositionsEcgArray.clear();
    for (int i = 0; i < R_peaksPositionsEcgArray.length; i++) {
      if ((i + 1) < R_peaksPositionsEcgArray.length) {
        for (int j = R_peaksPositionsEcgArray[i];
            j < R_peaksPositionsEcgArray[i + 1];
            j++) {
          if (j != R_peaksPositionsEcgArray[i]) {
            if (filterOPEcg[j] > filterOPEcg[j - 1] &&
                filterOPEcg[j] >= filterOPEcg[j + 1] &&
                filterOPEcg[j] >
                    0.09 *
                        (filterOPEcg.getRange(
                                filterOPEcg.length - 2000, filterOPEcg.length))
                            .reduce(math.max)) {
              T_peaksArrayEcg.add(filterOPEcg[j]);
              T_peaksPositionsEcgArray.add(j);
            }
          }
        }
      }
    }
    //print("T_peaksArrayEcg Length " + T_peaksArrayEcg.length.toString());
    //print("T_peaksArrayEcg Ecg" + T_peaksArrayEcg.toString());
    //print("T_peaksPositionsEcgArray Array " +T_peaksPositionsEcgArray.toString());
    rtIntervalList.clear();
    for (int i = 0; i < R_peaksPositionsEcgArray.length; i++) {
      for (int j = 0; j < T_peaksPositionsEcgArray.length; j++) {
        if (R_peaksPositionsEcgArray[i] < T_peaksPositionsEcgArray[j]) {
          if (((T_peaksPositionsEcgArray[j] - R_peaksPositionsEcgArray[i]) /
                  200) <
              0.5) {
            rtIntervalList.add(
                (T_peaksPositionsEcgArray[j] - R_peaksPositionsEcgArray[i]) /
                    200);
            // SumRt += rtIntervalList[i];
          }
        }
      }
    }
    SumRt = 0;
    for (int i = 0; i < rtIntervalList.length; i++) {
      SumRt += rtIntervalList[i];
    }
    // if (R_peaksPositionsEcgArray.length < T_peaksPositionsEcgArray.length) {
    //   for (int i = 0; i < R_peaksPositionsEcgArray.length; i++) {
    //     if (R_peaksPositionsEcgArray[i] < T_peaksPositionsEcgArray[i]) {
    //       rtIntervalList
    //           .add((T_peaksPositionsEcgArray[i] - R_peaksPositionsEcgArray[i])/200);
    //       SumRt += rtIntervalList[i];
    //     }
    //   }
    // } else {
    //   for (int i = 0; i < T_peaksPositionsEcgArray.length; i++) {
    //     if (R_peaksPositionsEcgArray[i] < T_peaksPositionsEcgArray[i]) {
    //       rtIntervalList
    //           .add((T_peaksPositionsEcgArray[i] - R_peaksPositionsEcgArray[i])/200);
    //       SumRt += rtIntervalList[i];
    //     }
    //   }
    // }
    //print("rtIntervalList ${rtIntervalList.toList()}");
    //print("SumRt ${SumRt}");

    if (rtIntervalList.isNotEmpty) {
      AvgRt = SumRt / rtIntervalList.length;
      BpFromRt = (210.86774418011 - (394.12035854481 * AvgRt)).round();
      //print("AvgRt ${AvgRt}");
      //print("BpFromRt $BpFromRt");
    }
    return;
  }

  static void stopIsolate() {
    print("kill RT_interval 1");
    RT_Interval.kill(priority: Isolate.immediate);
    print("kill RT_interval 2");
  }

  void countPpgHeartRate() {
    try {
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
      if (mainPpgDecimalList.length > Constant.filterDataListLength) {
        sgFilteredPpg = lfilter(
            b,
            Array([1.0]),
            Array(mainPpgDecimalList
                .getRange(
                    mainPpgDecimalList.length - Constant.filterDataListLength,
                    mainPpgDecimalList.length)
                .toList())); // filter the signal
      } else {
        sgFilteredPpg = lfilter(
            b, Array([1.0]), Array(mainPpgDecimalList)); // filter the signal
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
      filterOPPpg =
          lfilter(b1, Array([1.0]), sgFilteredPpg); // filter the signal

      // printLog("CCC sgFilteredPpg " +
      //     sgFilteredPpg.runtimeType.toString() +
      //     " " +
      //     sgFilteredPpg.length.toString());
      //
      // printLog("CCC filterOPPpg " +
      //     filterOPPpg.runtimeType.toString() +
      //     " " +
      //     filterOPPpg.length.toString());
      // printLog("CCC " + filterOPPpg.toString());
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
      // print("peaksArray.length ${R_peaksArrayEcg[index].length} ${peaksArrayPpg[index].length}");

      peaksPositionsPpgArray.clear();
      peaksArrayPpg.clear();
      for (int f = 2000; f < filterOPPpg.length; f++) {
        if (f - 1 > 0 && f + 1 < filterOPPpg.length) {
          // showSnackBar(
          //     "ffffff ${filterOPPpg[f]}   ${0.45 * (filterOPPpg.getRange(filterOPPpg.length - 2000, filterOPPpg.length)).reduce(math.max)}");

          // printLog("ffffff gh ${filterOPPpg[f]}   ${0.45 * (filterOPPpg.getRange(filterOPPpg.length - 2000, filterOPPpg.length)).reduce(math.max)}");

          if (filterOPPpg[f] > filterOPPpg[f - 1] &&
              filterOPPpg[f] >= filterOPPpg[f + 1] &&
              filterOPPpg[f] >
                  0.45 *
                      (filterOPPpg.getRange(
                              filterOPPpg.length - 2000, filterOPPpg.length))
                          .reduce(math.max)) {
            // showSnackBar("filterOPPpg for loop array inside if condition");

            peaksArrayPpg.add(filterOPPpg[f]);
            peaksPositionsPpgArray.add(f);
          }
        }
      }

      //print("Peaks_position Array " + peaksPositionsPpgArray.toString());
      // showSnackBar("peaksPositionsPpgArray_length ${peaksPositionsPpgArray.length.toString()}");

      // if (R_peaksArrayEcg[index].length < peaksArrayPpg[index].length) {
      //   tempPeakList = R_peaksArrayEcg[index];
      // } else {
      //   tempPeakList = peaksArrayPpg[index];
      // }
      pttArray.clear();
      prv.clear();
      hrv.clear();

      for (int p = 0; p < peaksPositionsPpgArray.length; p++) {
        if (p + 1 < peaksPositionsPpgArray.length) {
          if (((60 *
                      200 /
                      (peaksPositionsPpgArray[p + 1] -
                          peaksPositionsPpgArray[p]) <
                  500)) &&
              ((60 *
                      200 /
                      (peaksPositionsPpgArray[p + 1] -
                          peaksPositionsPpgArray[p]) >
                  0))) {
            prv.add((60 *
                200 /
                (peaksPositionsPpgArray[p + 1] - peaksPositionsPpgArray[p])));
          }
        }

        //print("uuu ecg");

        for (int e = 0; e < R_peaksPositionsEcgArray.length; e++) {
          //print("uuu ecg ${e.toString()} ${R_peaksPositionsEcgArray[e].toString()}");
          //print("uuu ppg ${p.toString()} ${peaksPositionsPpgArray[p].toString()}");
          if (e + 1 < R_peaksPositionsEcgArray.length) {
            if (((60 *
                        200 /
                        (R_peaksPositionsEcgArray[e + 1] -
                            R_peaksPositionsEcgArray[e]) <
                    500)) &&
                ((60 *
                        200 /
                        (R_peaksPositionsEcgArray[e + 1] -
                            R_peaksPositionsEcgArray[e]) >
                    0))) {
              hrv.add((60 *
                  200 /
                  (R_peaksPositionsEcgArray[e + 1] -
                      R_peaksPositionsEcgArray[e])));
            }
          }

          if (R_peaksPositionsEcgArray[e] < peaksPositionsPpgArray[p]) {
            double diff =
                ((peaksPositionsPpgArray[p] - R_peaksPositionsEcgArray[e]) /
                    200);
            //pttArray.add(diff);
            if (diff <= 0.8) {
              pttArray.add(diff);
              totalOfPeaksPpg +=
                  ((peaksPositionsPpgArray[p] - R_peaksPositionsEcgArray[e]) /
                      200);
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

      //print("rrrr prv:  ${prv.toList()} avg: ${avgPrv.toString()}");
      //print("rrrr hrv:  ${hrv.toList()} array: ${avgHrv.toString()}");

      //print("ggg pttArray_length:  ${pttArray.length} array: ${pttArray.toString()}");

      avgPTT = (totalOfPeaksPpg / (pttArray.length));
      //print("PTT1 $avgPTT");
      if (avgPTT.isNaN || avgPTT.isInfinite) {
        avgPTT = 0;
      }
      //print("PTT2 ${avgPTT}");
      //  showSnackBar("totalOfPeaksPpg  " + totalOfPeaksPpg.toString() + " avg " + avgPTT.toString());

      //print("ggg totalOfPeaksPpg  " + totalOfPeaksPpg.toString() + " avg " + avgPTT.toString());

      // dBp = 134.802365863 - 83.006119783168 * avgPTT;
      // dDbp = 99.606825109447 - 96.651802662872 * avgPTT;
      dBp = 145.802365863 - 83.006119783168 * avgPTT;
      dDbp = 110.606825109447 - 96.651802662872 * avgPTT;
      PP = dBp - dDbp;
      MAP = ((dBp + (2 * dDbp)) / 3);
      SV = dBp - dDbp;
      CO = ((SV * heartRate) / 1000);
      //print("avgPTT1 $avgPTT , avgHrv1 $avgHrv");
      // Constant.providerGraphData.avgPTT = avgPTT;
      // Constant.providerGraphData.avgHrv = avgHrv;
      // Constant.providerGraphData.avgPrv = avgPrv;
      // Constant.providerGraphData.dBp = dBp;
      // Constant.providerGraphData.dDbp = dDbp;
    } catch (Exception) {
      printLog("Exception ppg ${Exception.toString()}");
    }
  }

  // static Future<ArrhythmiaType> GetArrthmiaType(List<int> rrHeartList) async {
  //   print("GetArrthmiaType");
  //   final response = await http.post(
  //     Uri.parse(Constant.fastAPI + '/prediction'),
  //     headers: {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //     },
  //     body: jsonEncode({'data': rrHeartList}),
  //   );
  //   //jsonEncode(<String, List<int>>{
  //   //         'RR': rrHeartList,
  //   //       }),
  //   print("send response ${response.statusCode}");
  //   if (response.statusCode == 200) {
  //     print("success ArrhythmiaType");
  //     return ArrhythmiaType.fromJson(jsonDecode(response.body));
  //   } else {
  //     // If the server did not return a 201 CREATED response,
  //     // then throw an exception.
  //     throw Exception('Failed to create ArrthmiaType.');
  //   }
  // }

  void Prediction() async {
    try {
      final testList = DataFrame.fromJson({
        'H': ["rrInterval"],
        'R': rrInterval
      });
      //rrIntervalListModelClass rrIntervalList_model_class = new rrIntervalListModelClass();
      //rrIntervalList_model_class.rrIntervalList = rrIntervalList;
      // final rawCsvContent = await rootBundle.loadString(rrIntervalFilePath);
      //final testList = DataFrame.fromRawCsv(rawCsvContent);
      final prediction = classifier.predict(testList);
      print("prediction header ${prediction.header}");
      print("prediction rows ${prediction.rows}");
      dynamic type = prediction.rows.first.first;
      print("type ${type}");
      if (type == 0.0) {
        arrhythmia_type = "Normal";
      } else if (type == 1.0) {
        arrhythmia_type = "Bigeminy";
      } else if (type == 2.0) {
        arrhythmia_type = "Trigeminy";
      } else if (type == 3.0) {
        arrhythmia_type = "Ventricular Tachycardia";
      } else {
        arrhythmia_type = "No data";
      }
    } catch (CheckedFromJsonException) {
      arrhythmia_type = "Exception";
      print("Exception ${CheckedFromJsonException.toString()}");
    }
  }

  void TrainModel() async {
    final rawCsvContent = await rootBundle.loadString(csvFilePath);
    final samples = DataFrame.fromRawCsv(rawCsvContent, fieldDelimiter: ",");
    print(samples.header);
    final arrthmiaColumn = 'Arrhythmia';
    //final splits = splitData(samples, [0.7]);
    //final validationData = splits[0];
    //final testData = splits[1];
    //final validator = CrossValidator.kFold(validationData, numberOfFolds: 5);
    print("samples ${samples.rows.length}");
    createClassifier =
        (DataFrame samples) => KnnClassifier(samples, arrthmiaColumn, 4);
    print("createClassifier ${createClassifier.toString()}");
    // final scores = await validator.evaluate(
    //     createClassifier, MetricType.accuracy);
    // //final scores = await validator.evaluate(createClassifier, MetricType.accuracy,onDataSplit: 0.8);
    // final accuracy = scores.mean();
    // print('accuracy on k fold validation: ${accuracy.toString()}');
    //final testSplits = splitData(testData, [0.8]);
    classifier = createClassifier(samples);
    // final finalScore = classifier.assess(testSplits[1], MetricType.accuracy);
    // print("finalScore.toStringAsFixed(2) ${finalScore.toStringAsFixed(2)}");
  }
}
