import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Constant {
  String appName = "Bacancy Medical";
  String readUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String writeUuid = "00001525-1212-efde-1523-785feabcd123";
  String writeChangeModeUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

  int yAxisGraphData = 500;
 // int yAxisGraphInterval = 200;
  double xAxisInterval = 200; //bottom data
  double yAxisInterval = 1000; //left data
  int periodicTimeInSec = 8000;
  static int filterDataListLength = 4000;
  int filterDataListLength1 = 1600;

  String ppg = "PPG";
  String ecg = "ECG";
  String ecgNppg = "ECG & PPG";
  String spo2 = "Spo2";
  String strHeartRate = "Heart Rate:";
  String strStepCount = "Step Count:";
  String heartRateUnit = "BPM";
  String bpUnit = "mmHg";
  String rvUnit = "ms";

  static String fastAPI = "http://66.94.110.161:8001";

  String strNoDeviceConnected = "No device connected";
  String strConnect = "Connect";
  String displayDeviceString = "nordic";
  String strNoDevicesAvailable = "No devices are available";
  String strAvailableDevices = "Available Devices";
  static ProviderGraphData providerGraphData =new ProviderGraphData();
  static Map<int, Color> color = {
    50: Color.fromRGBO(35, 182, 230, .1),
    100: Color.fromRGBO(35, 182, 230, .2),
    200: Color.fromRGBO(35, 182, 230, .3),
    300: Color.fromRGBO(35, 182, 230, .4),
    400: Color.fromRGBO(35, 182, 230, .5),
    500: Color.fromRGBO(35, 182, 230, .6),
    600: Color.fromRGBO(35, 182, 230, .7),
    700: Color.fromRGBO(35, 182, 230, .8),
    800: Color.fromRGBO(35, 182, 230, .9),
    900: Color.fromRGBO(35, 182, 230, 1),
  };

  // MaterialColor clrPrimarySwatch = MaterialColor(0xFF23B6E6, color);
  MaterialColor clrPrimarySwatch = Colors.teal;

  // Color clrPrimary = Color(0xFF23B6E6);
  Color clrPrimary = Colors.teal;

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
