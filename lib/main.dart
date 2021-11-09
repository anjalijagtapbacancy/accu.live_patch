import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_connection/provider_ecg_data.dart';
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
    [DeviceOrientation.portraitUp],
  );
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
  final List<BluetoothDevice> devicesList = [];
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _services;
  var isServiceStarted = false;
  BluetoothCharacteristic? readCharacteristic;
  // writeCharacteristic
  var sub;
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];
  List<String> hexList = [];
  List<double> decimalList = [];

  List<FlSpot> spotsListData = [];

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    widget.flutterBlue.isOn.then((value) {
      print("Mirinda isOn ${value.toString()}");
      if (value) {
      } else {}
    });

    widget.flutterBlue.isAvailable.then((value) {
      print("Mirinda isAvailable ${value.toString()}");
    });

    widget.flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
      print("Mirinda devices ${devices.length}");

      for (BluetoothDevice device in devices) {
        print("Mirinda connectedDevices ${device}");

        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      print("Mirinda scan result length devices ${results.length}");

      for (ScanResult result in results) {
        print("Mirinda scanResults ${result.device}");
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    // if (e.code != 'already_connected') {
                    //   throw e;
                    // }
                    print(e.toString());
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
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
          readCharacteristic = characteristic;
          try {
            generateGraphValuesList(widget.readValues[readCharacteristic!.uuid]);
          } catch (err) {
            print(" caught err ${err.toString()}");
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Value: ' + decimalList.toString()),
        ),
        // ...containers,
        Visibility(
            visible: decimalList.isNotEmpty,
            child: AspectRatio(
              aspectRatio: 1.1,
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
          interval: decimalList.length / (decimalList.length),
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
          interval: (decimalList.isNotEmpty && decimalList.reduce(max) != 0)
              ? decimalList.reduce(max) / (decimalList.length)
              : 1,
          // interval: 100,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          getTitles: (value) {
            print(
                "getTitles max: ${decimalList.reduce(max)} interval: ${decimalList.reduce(max) / (decimalList.length)}");
            return value.toString();
          },
          reservedSize: 50,
          margin: 8,
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: double.parse(decimalList.length.toString()),
      minY: decimalList.isNotEmpty ? decimalList.reduce(min) : 0,
      maxY: decimalList.isNotEmpty ? decimalList.reduce(max) : 0,
      lineBarsData: [
        LineChartBarData(
          spots: spotsListData,
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
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Visibility(
            visible: decimalList.isNotEmpty,
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
            visible: _connectedDevice != null,
            child: TextButton(
                onPressed: () async {
                  if (isServiceStarted) {
                    print("stop service");
                    isServiceStarted = false;

                    //stop service
                    //    writeCharacteristic!.write( utf8.encode("0"));
                    //     if(sub!=null){
                    //    sub.cancel();

                    //  }

                    await readCharacteristic!.setNotifyValue(false);
                  } else {
                    // start service
                    //  writeCharacteristic!.write(utf8.encode("1"));
                    print("start service");
                    // ignore: cancel_subscriptions
                    if (sub != null) {
                      sub.cancel();
                    }

                    isServiceStarted = true;

                    await readCharacteristic!.setNotifyValue(true);
                    await Future.delayed(Duration(seconds: 2));

                    sub = readCharacteristic!.value.listen((value) {
                      setState(() {
                        widget.readValues[readCharacteristic!.uuid] = value;
                      });
                    });

                    await readCharacteristic!.read();
                  }
                },
                child: Text(
                  isServiceStarted ? "Stop" : "Start",
                  style: TextStyle(color: Colors.white),
                )),
          )
        ],
      ),
      body: _buildView());

  void generateGraphValuesList(List<int>? valueList) {
    if (valueList != null) {
      print("VVV valueList ${valueList.toString()}");

      hexList.clear();
      for (int i = 0; i < valueList.length; i++) {
        hexList.add(valueList[i].toRadixString(16));
      }
      print("VVV hexList ${hexList.toString()}");

      decimalList.clear();
      spotsListData.clear();

      for (int h = 0; h < hexList.length; h++) {
        if (h % 2 == 0) {
          String strHex = hexList[h + 1] + hexList[h];
          decimalList.add(double.parse(int.parse(strHex, radix: 16).toString()));
        }
      }

      for (int k = 0; k < hexList.length; k++) {
        spotsListData.add(FlSpot(double.tryParse(k.toString()) ?? 0, decimalList[k]));
      }

      print("VVV decimalList ${decimalList.toString()}");
      print("VVV spotsListData: ${spotsListData.toList()}");
    }
  }

  void _generateCsvFile() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    List<dynamic> associateList = [
      {"number": 1, "lat": "14.97534313396318", "lon": "101.22998536005622"},
      {"number": 2, "lat": "14.97534313396318", "lon": "101.22998536005622"},
      {"number": 3, "lat": "14.97534313396318", "lon": "101.22998536005622"},
      {"number": 4, "lat": "14.97534313396318", "lon": "101.22998536005622"}
    ];

    List<List<dynamic>> rows = [];

    for (int i = 0; i < decimalList.length; i++) {
      List<dynamic> row = [];
      row.add(decimalList[i]);
      rows.add(row);
    }

    String csvData = ListToCsvConverter().convert(rows);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/csv_ecg_data.csv";
    print(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    Share.shareFiles(['${file.path}'], text: 'Exported csv');
  }
}
