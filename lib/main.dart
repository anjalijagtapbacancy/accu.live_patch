import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:flutter_bluetooth_connection/provider_ecg_data.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/linear_chart.dart';
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProviderEcgData()),
        ],
        child: MaterialApp(
          title: 'BLE Connection',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: 'BLE Connection'),
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

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothService>? _services;
  var sub;
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  List<String> mainHexList = [];
  List<double> mainDecimalList = [];

  List<String> tempHexList = [];
  List<double> tempDecimalList = [];

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
        print("  isOn ${value.toString()}");
        if (value) {
        } else {}
      });

      widget.flutterBlue.isAvailable.then((value) {
        print(" isAvailable ${value.toString()}");
      });

      widget.flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
        print("  devices ${devices.length}");

        for (BluetoothDevice device in devices) {
          print("  connectedDevices ${device}");

          _addDeviceTolist(device);
        }
      });
      widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
        print("  scan result length devices ${results.length}");

        for (ScanResult result in results) {
          print("  scanResults ${result.device}");
          _addDeviceTolist(result.device);
        }
      });
      widget.flutterBlue.startScan();
    });
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in providerEcgDataWatch!.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              Expanded(
                // flex: 2,
                child: FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'Connect',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    providerEcgDataWatch!.setLoading(true);
                    widget.flutterBlue.stopScan();
                    try {
                      await device.connect();
                      await device.requestMtu(512);
                    } catch (e) {
                      // if (e.code != 'already_connected') {
                      //   throw e;
                      // }
                      print(e.toString());
                    } finally {
                      _services = await device.discoverServices();
                    }
                    providerEcgDataWatch!.setConnectedDevice(device);
                    providerEcgDataWatch!.setLoading(false);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildConnectDeviceView() {
    for (BluetoothService service in _services!) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "0000abf4-0000-1000-8000-00805f9b34fb") {
          try {
            providerEcgDataWatch!.setReadCharacteristic(characteristic);

            generateGraphValuesList(providerEcgDataWatch!.readValues[characteristic.uuid]);
          } catch (err) {
            print(" caught err ${err.toString()}");
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        // ...containers,
        Visibility(
            visible: tempDecimalList.isNotEmpty,
            child: AspectRatio(
              aspectRatio: 6 / (2.4),
              child: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Color(0xff232d37)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(
                    mainData(),
                  ),
                ),
              ),
            )),
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
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
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
              const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 13),
          getTitles: (value) {
            return value.toString();
          },
          margin: 8,
        ),
        // graph data
        leftTitles: SideTitles(
          showTitles: true,
          // interval: (decimalList.isNotEmpty && decimalList.reduce(max) != 0)
          //     ? decimalList.reduce(max) / (decimalList.length)
          //     : 1,
          interval: 2000,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          getTitles: (value) {
            print(
                "getTitles max: ${tempDecimalList.reduce(max)} interval: ${tempDecimalList.reduce(max) / (tempDecimalList.length)}");
            return value.toString();
          },
          reservedSize: 50,
          margin: 8,
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: providerEcgDataWatch!.tempSpotsListData.isNotEmpty ? providerEcgDataWatch!.tempSpotsListData.first.x : 0,
      maxX: providerEcgDataWatch!.tempSpotsListData.isNotEmpty ? providerEcgDataWatch!.tempSpotsListData.last.x + 1 : 0,

      // maxX: double.parse(spotsListData.length.toString()),
      // minY: decimalList.isNotEmpty ? decimalList.reduce(min) : 0,
      // maxY: decimalList.isNotEmpty ? decimalList.reduce(max) : 0,
      minY: 0,
      maxY: 18000,
      lineBarsData: [
        LineChartBarData(
          spots: providerEcgDataWatch!.tempSpotsListData,
          isCurved: true, // graph shape
          colors: gradientColors,
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
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            Visibility(
              visible: tempDecimalList.isNotEmpty,
              // visible: false,
              child: TextButton(
                  child: Text(
                    "Export",
                    style: TextStyle(color: Colors.white),
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
                      print("stop service");
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
                      print("start service");
                      // ignore: cancel_subscriptions
                      if (sub != null) {
                        sub.cancel();
                      }

                      providerEcgDataWatch!.setServiceStarted(true);

                      await providerEcgDataWatch!.readCharacteristic!.setNotifyValue(true);
                      providerEcgDataWatch!.setLoading(false);

                      await Future.delayed(Duration(seconds: 2));

                      sub = providerEcgDataWatch!.readCharacteristic!.value.listen((value) {
                        providerEcgDataWatch!.setReadValues(value);
                      });

                      await providerEcgDataWatch!.readCharacteristic!.read();
                    }
                  },
                  child: Text(
                    providerEcgDataWatch!.isServiceStarted ? "Stop" : "Start",
                    style: TextStyle(color: Colors.white),
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

  void generateGraphValuesList(List<int>? valueList) async {
    // await Future.delayed(Duration(microseconds: 200));

    if (valueList != null) {
      print("VVV valueList ${valueList.toString()}");

      // tempValueList = valueList.getRange(valueList.length - 10, valueList.length).toList();

      for (int i = 0; i < valueList.length; i++) {
        mainHexList.add(valueList[i].toRadixString(16).padLeft(2, '0'));
      }
      tempHexList = mainHexList.getRange(mainHexList.length - 1000, mainHexList.length).toList();
      for (int h = 0; h < tempHexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = tempHexList[h + 1] + tempHexList[h];
          mainDecimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }
      tempDecimalList = mainDecimalList.getRange(mainDecimalList.length - 500, mainDecimalList.length).toList();

      providerEcgDataWatch!.storeDataToLocal(tempDecimalList);
      providerEcgDataWatch!.setSpotsListData(tempDecimalList, mainDecimalList);

      // print("VVV valueList ${valueList.length} ${valueList.toString()} ");
      // print("VVV mainHexList ${mainHexList.length} ${mainHexList.toString()}");
      // print("VVV tempHexList ${tempHexList.length} ${tempHexList.toString()}");

      // print("VVV mainDecimalList ${mainDecimalList.length} ${mainDecimalList.toString()}");
      // print("VVV tempDecimalList ${tempDecimalList.length} ${tempDecimalList.toString()}");

      print(
          "VVV tempSpotsListData length: ${providerEcgDataWatch!.tempSpotsListData.length} spotsListData: ${providerEcgDataWatch!.tempSpotsListData.toList()}");
    }
  }

  void _generateCsvFile() async {
    // Map<Permission, PermissionStatus> statuses = await [
    //   Permission.storage,
    // ].request();
    providerEcgDataWatch!.setLoading(true);
    List<List<dynamic>> rows = [];
    await providerEcgDataWatch!.getStoreDataToLocal();

    for (int i = 0; i < providerEcgDataWatch!.savedLocalDataList.length; i++) {
      List<dynamic> row = [];
      row.add(providerEcgDataWatch!.savedLocalDataList[i]);
      rows.add(row);
    }

    String csvData = ListToCsvConverter().convert(rows);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/csv_ecg_data.csv";
    print(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerEcgDataWatch!.setLoading(false);

    Share.shareFiles(['${file.path}'], text: 'Exported csv');
  }
}
