import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:flutter_bluetooth_connection/provider_ecg_data.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.landscapeRight],
  );
  Directory directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  runApp(MyApp());
}

class MyApp extends StatelessWidget with Constant {
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProviderEcgData()),
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
          home: MyHomePage(title: appName),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with Constant {
  var sub;

  ProviderEcgData? providerEcgDataRead;
  ProviderEcgData? providerEcgDataWatch;

  _addDeviceTolist(final BluetoothDevice device) {
    providerEcgDataWatch!.setDeviceList(device);
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      providerEcgDataRead = context.read<ProviderEcgData>();

      widget.flutterBlue.isOn.then((value) {
        printLog("  isOn ${value.toString()}");
        if (value) {
        } else {}
      });

      widget.flutterBlue.isAvailable.then((value) {
        printLog(" isAvailable ${value.toString()}");
      });

      widget.flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
        printLog("  devices ${devices.length}");

        for (BluetoothDevice device in devices) {
          printLog("  connectedDevices ${device}");

          _addDeviceTolist(device);
        }
      });
      widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
        printLog("  scan result length devices ${results.length}");

        for (ScanResult result in results) {
          printLog("  scanResults ${result.device}");
          _addDeviceTolist(result.device);
        }
      });
      widget.flutterBlue.startScan();
    });
  }

  @override
  void dispose() {
    providerEcgDataWatch!.clearProviderEcgData();

    super.dispose();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in providerEcgDataWatch!.devicesList) {
      containers.add(
        Container(
          margin: EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(
                    device.name == '' ? '(unknown device)' : device.name,
                    style: TextStyle(color: clrWhite),
                  ),
                  Text(
                    device.id.toString(),
                    style: TextStyle(color: clrGrey),
                  ),
                ],
              ),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: clrPrimary, width: 1),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                  ),
                  child: Text(
                    'Connect',
                    style: TextStyle(color: clrPrimary, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () async {
                    printLog("Mirinda 0000");
                    providerEcgDataWatch!.setLoading(true);
                    widget.flutterBlue.stopScan();
                    printLog("Mirinda 1111");

                    try {
                      printLog("Mirinda 2222");

                      await device.connect();
                      printLog("Mirinda 33333");
                    } catch (e) {
                      printLog("Mirinda 4444");
                      // if (e.code != 'already_connected') {
                      //   throw e;
                      // }
                      printLog(e.toString());
                    } finally {
                      printLog("Mirinda 5555");
                      providerEcgDataWatch!.setConnectedDevice(device);
                      await device.requestMtu(512);

                      providerEcgDataWatch!.setLoading(false);

                      printLog("Mirinda 6666");
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildConnectDeviceView() {
    for (BluetoothService service in providerEcgDataWatch!.services!) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "0000abf4-0000-1000-8000-00805f9b34fb") {
          try {
            providerEcgDataWatch!.setReadCharacteristic(characteristic);
            if (providerEcgDataWatch!.isServiceStarted) {
              providerEcgDataWatch!.generateGraphValuesList(providerEcgDataWatch!.readValues[characteristic.uuid]);
            }
          } catch (err) {
            printLog(" caught err ${err.toString()}");
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        // ...containers,
        // providerEcgDataWatch!.tempDecimalList.isEmpty
        //     ? Center(
        //         child: Padding(
        //             padding: EdgeInsets.only(top: 120),
        //             child: Text(
        //               "Please start measurement ...",
        //               style: TextStyle(color: clrGrey, fontSize: 14),
        //             )))
        // :
        AspectRatio(
          aspectRatio: 6 / (2.4),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: clrDarkBg),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(
                mainData(),
              ),
            ),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Text('Value: ' + decimalList.toString()),
        // ),
      ],
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: clrGraphLine,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: clrGraphLine,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        // index / time
        bottomTitles: SideTitles(
          showTitles: true,
          // reservedSize: 22,
          // interval: providerEcgDataWatch!.savedLocalDataList.isNotEmpty
          //     ? providerEcgDataWatch!.savedLocalDataList.length / 100
          //     : 100,
          interval: 100,
          getTextStyles: (context, value) =>
              TextStyle(color: clrBottomTitles, fontWeight: FontWeight.bold, fontSize: 13),
          getTitles: (value) {
            return value.toString();
          },
          margin: 8,
        ),
        // graph data
        leftTitles: SideTitles(
          showTitles: true,
          interval: 2000,
          getTextStyles: (context, value) => TextStyle(
            color: clrLeftTitles,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          getTitles: (value) {
            return value.toString();
          },
          reservedSize: 50,
          margin: 8,
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: clrGraphLine, width: 1)),
      minX: providerEcgDataWatch!.tempSpotsListData.isNotEmpty ? providerEcgDataWatch!.tempSpotsListData.first.x : 0,
      maxX: providerEcgDataWatch!.tempSpotsListData.isNotEmpty ? providerEcgDataWatch!.tempSpotsListData.last.x + 1 : 0,
      minY: 0,
      maxY: 18000,
      lineBarsData: [
        LineChartBarData(
          spots: providerEcgDataWatch!.tempSpotsListData,
          isCurved: true, // graph shape
          colors: [clrPrimary, clrSecondary],
          barWidth: 1, //curve border width
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          // belowBarData: BarAreaData(
          //   show: true,
          //   colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          // ),
        ),
      ],
    );
  }

  ListView _buildView() {
    if (providerEcgDataWatch!.connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) {
    providerEcgDataWatch = context.watch<ProviderEcgData>();

    return Scaffold(
        backgroundColor: clrDarkBg,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: clrWhite),
          ),
          actions: [
            Visibility(
              visible: providerEcgDataWatch!.tempDecimalList.isNotEmpty,
              // visible: false,
              child: TextButton(
                  child: Text(
                    "Export",
                    style: TextStyle(color: clrWhite),
                  ),
                  onPressed: () {
                    _generateCsvFile();
                  }),
            ),
            Visibility(
              visible: providerEcgDataWatch!.connectedDevice != null,
              child: TextButton(
                  onPressed: () async {
                    if (providerEcgDataWatch!.isServiceStarted) {
                      providerEcgDataWatch!.setLoading(true);
                      printLog("stop service");
                      providerEcgDataWatch!.storeDataToLocal();
                      providerEcgDataWatch!.setServiceStarted(false);

                      //stop service
                      //    writeCharacteristic!.write( utf8.encode("0"));
                      //     if(sub!=null){
                      //    sub.cancel();
                      //  }

                      await providerEcgDataWatch!.readCharacteristic!.setNotifyValue(false);
                      providerEcgDataWatch!.setLoading(false);
                    } else {
                      providerEcgDataWatch!.setLoading(true);

                      await providerEcgDataWatch!.clearStoreDataToLocal();
                      // start service
                      //  writeCharacteristic!.write(utf8.encode("1"));
                      printLog("start service");
                      // ignore: cancel_subscriptions
                      if (sub != null) {
                        sub.cancel();
                      }

                      providerEcgDataWatch!.setServiceStarted(true);

                      await providerEcgDataWatch!.readCharacteristic!.setNotifyValue(true);
                      await Future.delayed(Duration(milliseconds: 200));
                      providerEcgDataWatch!.setLoading(false);

                      sub = providerEcgDataWatch!.readCharacteristic!.value.listen((value) {
                        providerEcgDataWatch!.setReadValues(value);
                      });

                      await providerEcgDataWatch!.readCharacteristic!.read();
                    }
                  },
                  child: Text(
                    providerEcgDataWatch!.isServiceStarted ? "Stop" : "Start",
                    style: TextStyle(color: clrWhite),
                  )),
            )
          ],
        ),
        body: Stack(
          children: [
            _buildView(),
            providerEcgDataWatch!.isLoading ? ProgressBar() : Offstage(),
          ],
        ));
  }

  // for (int k = decimalList.length; k > 0; k--) {
  //   if (k == decimalList.length - 5) {
  //     break;
  //   }

  void _generateCsvFile() async {
    // Map<Permission, PermissionStatus> statuses = await [
    //   Permission.storage,
    // ].request();
    providerEcgDataWatch!.setLoading(true);
    List<List<dynamic>> rows = [];
    await providerEcgDataWatch!.getStoredLocalData();

    for (int i = 0; i < providerEcgDataWatch!.savedLocalDataList.length; i++) {
      List<dynamic> row = [];
      row.add(providerEcgDataWatch!.savedLocalDataList[i]);
      rows.add(row);
    }

    String csvData = ListToCsvConverter().convert(rows);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/csv_ecg_data.csv";
    printLog(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerEcgDataWatch!.setLoading(false);

    Share.shareFiles(['${file.path}'], text: 'Exported csv');
  }
}
