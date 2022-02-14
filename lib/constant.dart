import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:moving_average/moving_average.dart';

class Constant {
  String appName = "Accu.Live Patch";
  String readUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String writeUuid = "00001525-1212-efde-1523-785feabcd123";
  String writeChangeModeUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  String csvFilePath="assets/datasets/all_samples_training.csv";
  int yAxisGraphData = 800;//500
 // int yAxisGraphInterval = 200;
  double xAxisInterval = 1.5; //200 bottom data
  double yAxisInterval = 0.5; //1000 left data
  int periodicTimeInSec = 8100;//8000,7200
  int filterDataListLength = 4050;//4000,3600
  int filterDataListLength1 = 1620;//1600,1440

  String ppg = "PPG";
  String ecg = "ECG";
  String ecgNppg = "ECG & PPG";
  String spo2 = "Spo2";
  String strHeartRate = "Heart Rate";
  String strStepCount = "Step Count";
  String strBpRt = "BPFromECG";
  String heartRateUnit = "BPM";
  String bpUnit = "mmHg";
  String rvUnit = "ms";

  final average_numbers_ecg = MovingAverage<num>(
    averageType: AverageType.simple,
    windowSize: 7, // 4,7
    partialStart: true,
    getValue: (num n) => n,
    add: (List<num> data, num value) => value,
  );
  final average_numbers_ppg = MovingAverage<num>(
    averageType: AverageType.simple,
    windowSize: 4, // 4,7
    partialStart: true,
    getValue: (num n) => n,
    add: (List<num> data, num value) => value,
  );

  String strConnect = "Connect";
  String displayDeviceString = "patch";
  String strNoDevicesAvailable = "No devices are available";

  static const int _blackPrimaryValue = 0xFF0C0C0C;
  // MaterialColor clrPrimarySwatch = MaterialColor(0xFF23B6E6, color);
  MaterialColor clrPrimarySwatch = MaterialColor(
    _blackPrimaryValue,
    <int, Color>{
      50: Color(0xFF0C0C0C),
      100: Color(0xFF0C0C0C),
      200: Color(0xFF0C0C0C),
      300: Color(0xFF0C0C0C),
      400: Color(0xFF0C0C0C),
      500: Color(_blackPrimaryValue),
      600: Color(0xFF0C0C0C),
      700: Color(0xFF0C0C0C),
      800: Color(0xFF0C0C0C),
      900: Color(0xFF0C0C0C),
    },
  );

  // Color clrPrimary = Color(0xFF23B6E6);
  Color clrPrimary = Color(0xFF4CBB17);
  Color clrdrawerHeader = Color(0xFF7CC16A);
  Color clrPrimaryYellow = Color(0xFFEFE139);
  Color clrPrimaryRed = Color(0xFFF32D31);

  Color clrecg = Color(0xfffa7602);
  Color clrecg2 = Color(0xfff3ab7b);

  //Color clrecg = Color(0xfffad902);
  //Color clrecg2 = Color(0xffebef90);
  Color clrppg = Color(0xff06e1f1);
  Color clrppg2 = Color(0xff92eff5);
  Color clrDarkBg = Color(0xff232d37);
  Color clrdeviceCard = Color(0xff343434);

  Color clrGraphLine = Color(0xff37434d);
  Color clrBottomTitles = Color(0xff68737d);
  Color clrLeftTitles = Color(0xff67727d);

  Color clrGrey = Color(0xff303a44);

  Color clrWhite = Colors.white;
  Color clrBlack = Colors.black;
  Color clrred = Color(0xFFF50707);
  Color clrgreen = Color(0xFF2DEC32);

  printLog(String msg) {
    // if (msg.contains("periodicTask") || msg.contains("heartRate")) {
    print(msg);
    // }
  }
}
