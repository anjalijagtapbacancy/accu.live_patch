import 'dart:ui';

import 'package:flutter/material.dart';

class Constant {
  String appName = "BLE Connection";
  String readUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String writeUuid = "00001525-1212-efde-1523-785feabcd123";
  int valueListLength = 200;
  int yAxisGraphData = 500;
  double xAxisInterval = 100; //bottom data
  double yAxisInterval = 1000; //left data

  String ppg = "PPG";
  String ecg = "ECG";

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

  MaterialColor clrPrimarySwatch = MaterialColor(0xFF23B6E6, color);
  Color clrPrimary = Color(0xFF23B6E6);
  Color clrSecondary = Color(0xff02d39a);
  Color clrDarkBg = Color(0xff232d37);

  Color clrGraphLine = Color(0xff37434d);
  Color clrBottomTitles = Color(0xff68737d);
  Color clrLeftTitles = Color(0xff67727d);

  Color clrGrey = Colors.grey;

  Color clrWhite = Colors.white;
  Color clrBlack = Colors.black;

  printLog(String msg) {
    print(msg);
  }
}
