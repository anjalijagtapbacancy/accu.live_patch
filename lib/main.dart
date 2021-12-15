import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:flutter_bluetooth_connection/discover_devices_screen.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ModelClass/Prediction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  Directory directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  runApp(MyApp());
}

class MyApp extends StatelessWidget with Constant {
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProviderGraphData()),
        ],
        child: MaterialApp(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                primarySwatch: clrPrimarySwatch,
                textTheme: TextTheme(
                  button: TextStyle(color: clrWhite),
                  bodyText1: TextStyle(color: clrWhite),
                  bodyText2: TextStyle(color: clrWhite),
                )),
            // home: MyHomePage(title: appName),
            home: DiscoverDevices()),
      );
}
