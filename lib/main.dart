import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
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

class _MyHomePageState extends State<MyHomePage> with Constant, SingleTickerProviderStateMixin {
  TabController? _controller;

  var sub;

  ProviderGraphData? providerGraphDataRead;
  ProviderGraphData? providerGraphDataWatch;

  @override
  void initState() {
    super.initState();

    // Create TabController for getting the index of current tab
    _controller = TabController(length: 4, vsync: this);

    _controller!.addListener(() {
      if (_controller!.index == 0) {
        // ecg/ppg
        providerGraphDataWatch!.writeChangeModeCharacteristic!.write([4]);
      }
      if (_controller!.index == 1) {
        // ecg
        providerGraphDataWatch!.writeChangeModeCharacteristic!.write([5]);
      }
      if (_controller!.index == 2) {
        // ppg
        providerGraphDataWatch!.writeChangeModeCharacteristic!.write([6]);
      }
      if (_controller!.index == 3) {
        // spo2
        providerGraphDataWatch!.writeChangeModeCharacteristic!.write([7]);
      }

      print("Selected Index: " + _controller!.index.toString());
    });

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      providerGraphDataRead = context.read<ProviderGraphData>();

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

          if (device.name.toLowerCase().contains(displayDeviceString)) {
            providerGraphDataWatch!.setDeviceList(device);
          }
        }
      });

      // if (providerGraphDataWatch!.devicesList.length == 1) {
      //   print("devicesList iff ${providerGraphDataWatch!.devicesList.length.toString()}");
      //   connectDevice(providerGraphDataWatch!.devicesList.first);
      // } else {
      //   print("devicesList elsee ${providerGraphDataWatch!.devicesList.length.toString()}");
      // }

      widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
        printLog("  scan result length devices ${results.length}");
        for (ScanResult result in results) {
          printLog("  scanResults ${result.device}");
          if (result.device.name.toLowerCase().contains(displayDeviceString)) {
            providerGraphDataWatch!.setDeviceList(result.device);
          }
        }
      });

      widget.flutterBlue.startScan();
    });
  }

  @override
  void dispose() {
    providerGraphDataWatch!.clearProviderGraphData();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    providerGraphDataWatch = context.watch<ProviderGraphData>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: clrDarkBg,
        appBar: AppBar(
          bottom: new PreferredSize(
              preferredSize: new Size(200.0, 200.0),
              child: new Container(
                height: 32.0,
                child: TabBar(
                  tabs: [
                    _tabWidget(ecgNppg),
                    _tabWidget(ecg),
                    _tabWidget(ppg),
                    _tabWidget(spo2),
                  ],
                ),
              )),
          title: Text(
            widget.title,
            style: TextStyle(color: clrWhite),
          ),
          actions: [
            Visibility(
              visible: !(providerGraphDataWatch!.connectedDevice != null),
              // visible: false,
              child: IconButton(
                  icon: Icon(
                    // providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
                    providerGraphDataWatch!.isShowAvailableDevices ? Icons.bluetooth_disabled : Icons.bluetooth_audio,
                    color: clrWhite,
                  ),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      providerGraphDataWatch!.setIsShowAvailableDevices();
                    }
                  }),
            ),
            Visibility(
              visible:
                  providerGraphDataWatch!.isServiceStarted && providerGraphDataWatch!.tempEcgDecimalList.isNotEmpty,
              // visible: false,
              child: TextButton(
                  child: Text(
                    providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
                    style: TextStyle(color: clrWhite),
                  ),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      providerGraphDataWatch!.setIsEnabled();
                    }
                  }),
            ),
            Visibility(
              visible: providerGraphDataWatch!.connectedDevice != null,
              child: TextButton(
                  onPressed: () async {
                    if (!providerGraphDataWatch!.isLoading) {
                      try {
                        if (providerGraphDataWatch!.isServiceStarted) {
                          try {
                            await providerGraphDataWatch!.readCharacteristic!.setNotifyValue(false);
                          } catch (err) {
                            printLog("notfy err ${err.toString()}");
                          }

                          providerGraphDataWatch!.setLoading(true);
                          printLog("stop service");

                          //stop service
                          providerGraphDataWatch!.writeCharacteristic!.write([0]);
                          if (sub != null) {
                            sub.cancel();
                          }
                          providerGraphDataWatch!.setServiceStarted(false);

                          await providerGraphDataWatch!.storedDataToLocal();

                          providerGraphDataWatch!.setLoading(false);
                        } else {
                          await providerGraphDataWatch!.readCharacteristic!.setNotifyValue(true);

                          providerGraphDataWatch!.setLoading(true);

                          await providerGraphDataWatch!.clearStoreDataToLocal();
                          // start service
                          providerGraphDataWatch!.writeCharacteristic!.write([1]);
                          printLog("start service");
                          // ignore: cancel_subscriptions
                          if (sub != null) {
                            sub.cancel();
                          }

                          providerGraphDataWatch!.setServiceStarted(true);
                          providerGraphDataWatch!.setLoading(false);

                          sub = providerGraphDataWatch!.readCharacteristic!.value.listen((value) {
                            providerGraphDataWatch!.setReadValues(value);
                          });

                          await providerGraphDataWatch!.readCharacteristic!.read();
                        }
                      } catch (e) {
                        printLog("err $e");
                      }
                    }
                  },
                  child: Text(
                    providerGraphDataWatch!.isServiceStarted ? "Stop" : "Start",
                    style: TextStyle(color: clrWhite),
                  )),
            ),
            Visibility(
              visible:
                  !providerGraphDataWatch!.isServiceStarted && providerGraphDataWatch!.tempEcgDecimalList.isNotEmpty,
              child: IconButton(
                  icon: Icon(Icons.share, color: clrWhite),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      _generateCsvFile();
                    }
                  }),
            ),
          ],
          toolbarHeight: 78,
        ),
        body: Stack(
          children: [
            (providerGraphDataWatch!.connectedDevice != null)
                ? TabBarView(
                    controller: _controller,
                    children: [
                      _ecgPpgView(),
                      _ecgTabView(),
                      _ppgTabView(),
                      _spo2TabView(),
                    ],
                  )
                : providerGraphDataWatch!.isShowAvailableDevices
                    ? showAvailableDevices()
                    : Center(child: Text(strNoDeviceConnected)),
            providerGraphDataWatch!.isLoading ? ProgressBar() : Offstage(),
          ],
        ),
      ),
    );
  }

  void connectDevice(BluetoothDevice device) async {
    providerGraphDataWatch!.setLoading(true);
    widget.flutterBlue.stopScan();

    try {
      await device.connect();
    } catch (e) {
      // if (e.code != 'already_connected') {
      //   throw e;
      // }
      printLog(e.toString());
    } finally {
      providerGraphDataWatch!.setConnectedDevice(device, context);
      providerGraphDataWatch!.setIsShowAvailableDevices();
      providerGraphDataWatch!.setLoading(false);
    }
  }

  Widget showAvailableDevices() {
    List<Container> availableDevicesView = [];

    for (BluetoothDevice device in providerGraphDataWatch!.devicesList) {
      availableDevicesView.add(
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
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: clrWhite, width: 1),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                  ),
                  child: Text(
                    strConnect,
                    style: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () async {
                    connectDevice(device);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 50, vertical: 25),
      color: Colors.blueGrey,
      elevation: 18,
      shadowColor: Colors.blueGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
          width: double.maxFinite,
          // decoration: BoxDecoration(
          //   color: Colors.black26,
          //   borderRadius: BorderRadius.circular(28),
          // ),
          // decoration: BoxDecoration(
          //   color: Colors.black26,
          //   borderRadius: BorderRadius.only(
          //       topLeft: Radius.circular(10),
          //       topRight: Radius.circular(10),
          //       bottomLeft: Radius.circular(10),
          //       bottomRight: Radius.circular(10)),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black26.withOpacity(0.5),
          //       spreadRadius: 5,
          //       blurRadius: 7,
          //       offset: Offset(0, 3), // changes position of shadow
          //     ),
          //   ],
          // ),

          child: availableDevicesView.isNotEmpty
              ? ListView(
                  padding: EdgeInsets.all(16),
                  children: <Widget>[
                    ...availableDevicesView,
                  ],
                )
              : Center(
                  child: Text(
                    strNoDevicesAvailable,
                    style: TextStyle(color: clrWhite),
                  ),
                )),
    );
  }

  ListView _ecgPpgView() {
    for (BluetoothService service in providerGraphDataWatch!.services!) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == writeChangeModeUuid) {
          try {
            providerGraphDataWatch!.setWriteChangeModeCharacteristic(characteristic);
          } catch (err) {
            printLog("setWriteChangeModeCharacteristic caught err ${err.toString()}");
          }
        }
        if (characteristic.uuid.toString() == writeUuid) {
          try {
            providerGraphDataWatch!.setWriteCharacteristic(characteristic);
          } catch (err) {
            printLog("setWriteCharacteristic caught err ${err.toString()}");
          }
        }
        if (characteristic.uuid.toString() == readUuid) {
          printLog("readUUid matched ! ${readUuid.toString()}");
          try {
            providerGraphDataWatch!.setReadCharacteristic(characteristic);
            if (providerGraphDataWatch!.isServiceStarted) {
              providerGraphDataWatch!.generateGraphValuesList(providerGraphDataWatch!.readValues[characteristic.uuid]);
            }
          } catch (err) {
            printLog(" caught err ${err.toString()}");
          }
        }
      }
    }

    return ListView(
      padding: EdgeInsets.only(top: 8, right: 8),
      children: <Widget>[
        rowTitle(ppg, providerGraphDataWatch!.heartRatePPG),
        graphWidget(ppg),
        rowTitle(ecg, providerGraphDataWatch!.heartRate),
        graphWidget(ecg)
      ],
    );
  }

  Widget rowTitle(String title, dynamic iHeartRate) {
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Visibility(
              visible: providerGraphDataWatch!.isEnabled
              // &&
              // providerGraphDataWatch!.heartRate < 150 &&
              // providerGraphDataWatch!.heartRate > 60
              ,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$strHeartRate " + iHeartRate.toString() + " $heartRateUnit",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget graphWidget(String title) {
    return AspectRatio(
      aspectRatio: 6 / (1.02),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(18),
            ),
            color: clrDarkBg),
        child: Padding(
          padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
          child: LineChart(title == ecg
              ? mainData(providerGraphDataWatch!.tempEcgSpotsListData, providerGraphDataWatch!.tempEcgDecimalList)
              : mainData(providerGraphDataWatch!.tempPpgSpotsListData, providerGraphDataWatch!.tempPpgDecimalList)),
        ),
      ),
    );
  }

  LineChartData mainData(List<FlSpot> tempSpotsList, List<double> tempDecimalList) {
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
          interval: xAxisInterval,
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
          interval: tempDecimalList.isNotEmpty
              ? (tempDecimalList.reduce(max) - tempDecimalList.reduce(min)) / 4 != 0
                  ? (tempDecimalList.reduce(max) - tempDecimalList.reduce(min)) / 4
                  : yAxisInterval
              : yAxisInterval,
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
      minX: tempSpotsList.isNotEmpty ? tempSpotsList.first.x : 0,
      maxX: tempSpotsList.isNotEmpty ? tempSpotsList.last.x + 1 : 0,
      minY: tempDecimalList.isNotEmpty ? tempDecimalList.reduce(min) : 0,
      maxY: tempDecimalList.isNotEmpty ? tempDecimalList.reduce(max) : 0,
      lineBarsData: [
        LineChartBarData(
          spots: tempSpotsList,
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

  Widget _ecgTabView() {
    return ListView(
      padding: EdgeInsets.only(top: 8, right: 8),
      children: [
        rowTitle(ecg, providerGraphDataWatch!.heartRate),
        AspectRatio(
          aspectRatio: 3 / (1),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: clrDarkBg),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(
                  mainData(providerGraphDataWatch!.tempEcgSpotsListData, providerGraphDataWatch!.tempEcgDecimalList)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ppgTabView() {
    return ListView(
      padding: EdgeInsets.only(top: 8, right: 8),
      children: [
        rowTitle(ppg, providerGraphDataWatch!.heartRatePPG),
        AspectRatio(
          aspectRatio: 3 / (1),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: clrDarkBg),
            child: Padding(
              padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(
                  mainData(providerGraphDataWatch!.tempPpgSpotsListData, providerGraphDataWatch!.tempPpgDecimalList)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spo2TabView() {
    return Icon(Icons.directions_transit);
  }

  Widget _tabWidget(String title) {
    return Tab(
        icon: Text(
      title,
      style: TextStyle(color: clrWhite),
    ));
  }

  void _generateCsvFile() async {
    providerGraphDataWatch!.setLoading(true);
    List<List<dynamic>> column = [];
    List<dynamic> row = [];

    // row.add("ecg");
    // row.add("ppg");
    // column.add(row);

    // await providerGraphDataWatch!.getStoredLocalData();

    // for (int i = 0; i < providerGraphDataWatch!.savedEcgLocalDataList.length; i++) {
    //   row = [];
    //   row.add(providerGraphDataWatch!.savedEcgLocalDataList[i]);
    //   row.add(providerGraphDataWatch!.savedPpgLocalDataList[i]);
    //   column.add(row);
    // }

    // String csvData = ListToCsvConverter().convert(column);
    // final String directory = (await getApplicationSupportDirectory()).path;
    // final path = "$directory/csv_graph_data.csv";
    // printLog(path);
    // final File file = File(path);
    // await file.writeAsString(csvData);
    // providerGraphDataWatch!.setLoading(false);

    // Share.shareFiles(['${file.path}'], text: 'Exported csv');

    for (int i = 0; i < providerGraphDataWatch!.filterOPPpg.length; i++) {
      row = [];
      row.add(providerGraphDataWatch!.filterOPPpg[i]);
      column.add(row);
    }

    String csvData = ListToCsvConverter().convert(column);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/filterOp_ppg_data.csv";
    printLog(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerGraphDataWatch!.setLoading(false);
    Share.shareFiles(['${file.path}'], text: 'Filter Op PPg csv');
  }
}
