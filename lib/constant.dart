import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';

class Constant {
  String appName = "Accu.Live Patch";
  String readUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String writeUuid = "00001525-1212-efde-1523-785feabcd123";
  String writeChangeModeUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  String csvFilePath="assets/datasets/all_samples_training.csv";
  int yAxisGraphData = 500;//500
 // int yAxisGraphInterval = 200;
  double xAxisInterval = 1; //200 bottom data
  double yAxisInterval = 0.5; //1000 left data
  int periodicTimeInSec = 8100;//8000,7200
  static int filterDataListLength = 4050;//4000,3600
  int filterDataListLength1 = 1620;//1600,1440

  String ppg = "PPG";
  String ecg = "ECG";
  String ecgNppg = "ECG & PPG";
  String spo2 = "Spo2";
  String strHeartRate = "Heart Rate";
  String strStepCount = "Step Count";
  String strBpRt = "BPfromECG";
  String heartRateUnit = "BPM";
  String bpUnit = "mmHg";
  String rvUnit = "ms";

  final average_numbers = MovingAverage<num>(
    averageType: AverageType.weighted,
    windowSize: 6, // 4,7
    partialStart: true,
    getValue: (num n) => n,
    add: (List<num> data, num value) => value,
  );

  String strConnect = "Connect";
  String displayDeviceString = "patch";
  String strNoDevicesAvailable = "No devices are available";


  // MaterialColor clrPrimarySwatch = MaterialColor(0xFF23B6E6, color);
  MaterialColor clrPrimarySwatch = Colors.teal;

  // Color clrPrimary = Color(0xFF23B6E6);
  Color clrPrimary = Color(0xFF009688);

  Color clrSecondary = Color(0xff02d39a);
  Color clrDarkBg = Color(0xff232d37);

  Color clrGraphLine = Color(0xff37434d);
  Color clrBottomTitles = Color(0xff68737d);
  Color clrLeftTitles = Color(0xff67727d);

  Color clrGrey = Colors.grey;

  Color clrWhite = Colors.white;
  Color clrBlack = Colors.black;

  printLog(String msg) {
    // if (msg.contains("periodicTask") || msg.contains("heartRate")) {
    print(msg);
    // }
  }
}
