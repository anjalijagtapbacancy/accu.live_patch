import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/linear_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE Demo'),
        // home: LineChartPage(),
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
  BluetoothCharacteristic? writeCharacteristic, readCharacteristic;
  var sub;

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
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
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
// 6e400003-b5a3-f393-e0a9-e50e24dcca9e


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

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = [];

    // if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text(isServiceStarted ? "Stop": "Start", style: TextStyle(color: Colors.white)),
              onPressed: () async {
if(isServiceStarted) {
   print("stop service");
  isServiceStarted = false;

   

  //stop service
   writeCharacteristic!.write( utf8.encode("0"));
    if(sub!=null){
   sub.cancel();

 }

} else {
  // start service
   writeCharacteristic!.write(utf8.encode("1"));
   print("start service");
 // ignore: cancel_subscriptions
 if(sub!=null){
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
            ),
          ),
        ),
      );
    // }
    // if (characteristic.properties.write) {
    //   buttons.add(
    //     ButtonTheme(
    //       minWidth: 10,
    //       height: 20,
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 4),
    //         child: RaisedButton(
    //           child: Text('WRITE', style: TextStyle(color: Colors.white)),
    //           onPressed: () async {
    //             await showDialog(
    //                 context: context,
    //                 builder: (BuildContext context) {
    //                   return AlertDialog(
    //                     title: Text("Write"),
    //                     content: Row(
    //                       children: <Widget>[
    //                         Expanded(
    //                           child: TextField(
    //                             controller: _writeController,
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                     actions: <Widget>[
    //                       FlatButton(
    //                         child: Text("Send"),
    //                         onPressed: () {
    //                           characteristic.write(
    //                               utf8.encode(_writeController.value.text));
    //                           Navigator.pop(context);
    //                         },
    //                       ),
    //                       FlatButton(
    //                         child: Text("Cancel"),
    //                         onPressed: () {
    //                           Navigator.pop(context);
    //                         },
    //                       ),
    //                     ],
    //                   );
    //                 });
    //           },
    //         ),
    //       ),
    //     ),
    //   );
    // }
    // if (characteristic.properties.notify) {
    //   buttons.add(
    //     ButtonTheme(
    //       minWidth: 10,
    //       height: 20,
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 4),
    //         child: RaisedButton(
    //           child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
    //           onPressed: () async {
    //             characteristic.value.listen((value) {
    //               widget.readValues[characteristic.uuid] = value;
    //             });
    //             await characteristic.setNotifyValue(true);
    //           },
    //         ),
    //       ),
    //     ),
    //   );
    // }

    return buttons;
  }

void setNotificationEnable() async{
  await Future.delayed(Duration(seconds: 2));

  sub = readCharacteristic!.value.listen((value) {
                  setState(() {
                    widget.readValues[readCharacteristic!.uuid] = value;
                  });
                });
  await readCharacteristic!.read();
}

  ListView _buildConnectDeviceView() {
    List<Container> containers = [];

    for (BluetoothService service in _services!) {
      List<Widget> characteristicsWidget = [];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print("AAA ${characteristic.uuid.toString()}");

        if(characteristic.uuid.toString() == "6e400003-b5a3-f393-e0a9-e50e24dcca9e"){
          print("AAA id matched!");
          readCharacteristic = characteristic;

        }

        if(characteristic.uuid.toString() == "6e400003-b5a3-f393-e0a9-e50e24dcca9e"){
          writeCharacteristic = characteristic;

        }
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                // Row(
                //   children: <Widget>[
                //     ..._buildReadWriteNotifyButton(characteristic),
                //   ],
                // ),
                
                    // Text('Value: ' +
                    //     widget.readValues[characteristic.uuid].toString()),

                    Text('Value: ' +
                        utf8.decode((widget.readValues[characteristic.uuid])!)),
                
                Divider(),
              ],
            ),
          ),
        );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
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
 TextButton(onPressed:


 () async {
if(isServiceStarted) {
   print("stop service");
  isServiceStarted = false;

   

  //stop service
   writeCharacteristic!.write( utf8.encode("0"));
    if(sub!=null){
   sub.cancel();

 }

} else {
  // start service
   writeCharacteristic!.write(utf8.encode("1"));
   print("start service");
 // ignore: cancel_subscriptions
 if(sub!=null){
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
               
              
              
 } , child: Text(isServiceStarted ? "Stop": "Start", style: TextStyle(color: Colors.white),
          
            
 ))
          ],
        ),
        body: _buildView(),
      );
}
