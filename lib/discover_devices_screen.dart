import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_connection/constant.dart';

import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/utils.dart';
import 'package:provider/provider.dart';
import 'graph_screen.dart';

class DiscoverDevices extends StatefulWidget {
  DiscoverDevices({Key? key}) : super(key: key);

  @override
  DiscoverDevicesState createState() => DiscoverDevicesState();
}

class DiscoverDevicesState extends State<DiscoverDevices> with Constant, Utils {
  ProviderGraphData? providerGraphDataRead;
  ProviderGraphData? providerGraphDataWatch;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  var sub;
  String? choice = "ECG & PPG";

  StreamSubscription? connDeviceSub;
  StreamSubscription? bluetoothConnSub;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      providerGraphDataRead = context.read<ProviderGraphData>();
      chechBluetooth();
      providerGraphDataRead!.enableLocation();
      providerGraphDataRead!.TrainModel();
      if (providerGraphDataRead!.connectedDevice != null) {
        connDeviceSub =
            providerGraphDataRead!.connectedDevice!.state.listen((event) async {
          showToast("device event ${event.toString()}");
          if (event == BluetoothDeviceState.disconnected) {
            providerGraphDataRead!.clearConnectedDevice();
            providerGraphDataRead!.setLoading(false);
            scanDevices();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    bluetoothConnSub!.cancel();
    connDeviceSub!.cancel();
    providerGraphDataWatch!.clearProviderGraphData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    providerGraphDataWatch = context.watch<ProviderGraphData>();

    return Scaffold(
      backgroundColor: Colors.black12,
      appBar: AppBar(
        title: Text(
          "Discover Devices",
          style: TextStyle(color: clrWhite),
        ),
        actions: [
          TextButton(
              child: Text(
                providerGraphDataWatch!.isScanning ? "Stop" : "Scan",
                style: TextStyle(color: clrWhite),
              ),
              onPressed: () async {
                if (!providerGraphDataWatch!.isLoading) {
                  if (providerGraphDataWatch!.isScanning) {
                    //stop scan
                    providerGraphDataWatch!.setLoading(true);
                    await this.flutterBlue.stopScan();
                    providerGraphDataWatch!.setIsScanning(false);
                    providerGraphDataWatch!.setLoading(false);
                  } else {
                    //start scan
                    providerGraphDataWatch!.setLoading(true);
                    providerGraphDataWatch!.setIsScanning(true);
                    providerGraphDataWatch!.setLoading(false);
                    providerGraphDataWatch!.enableLocation();
                    providerGraphDataWatch!.devicesList.clear();
                    chechBluetooth();
                  }
                }
              }),
          SizedBox(width: 8)
        ],
      ),
      body: Stack(
        children: [
          providerGraphDataWatch!.devicesList.length > 0
              ? ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                  itemCount: providerGraphDataWatch!.devicesList.length,
                  separatorBuilder: (context, i) {
                    return Divider(
                        );
                  },
                  itemBuilder: (context, i) {
                    return Card(
                      color: clrDarkBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_services_outlined,
                                  color: clrPrimary,
                                ),
                                SizedBox(width: 25),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      providerGraphDataWatch!
                                                  .devicesList[i].name ==
                                              ''
                                          ? '(unknown device)'
                                          : providerGraphDataWatch!
                                              .devicesList[i].name,
                                      style: TextStyle(color: clrWhite),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      providerGraphDataWatch!.devicesList[i].id
                                          .toString(),
                                      style: TextStyle(
                                          color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 200,
                              child: OutlinedButton(
                                  style: TextButton.styleFrom(
                                    side: BorderSide(
                                        color: clrWhite.withOpacity(0.4),
                                        width: 1),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(25))),
                                  ),
                                  child: Text(
                                    strConnect,
                                    style: TextStyle(
                                        color: Colors.grey.shade200,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onPressed: () async {
                                    connectDevice(
                                        providerGraphDataWatch!.devicesList[i]);
                                  }),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
              : Center(child: Text(strNoDevicesAvailable)),
          providerGraphDataWatch!.isLoading ? ProgressBar() : Offstage(),
        ],
      ),
    );
  }

  void chechBluetooth() {
    bluetoothConnSub = flutterBlue.state.listen((event) async {
      switch (event) {
        case BluetoothState.on:
          Utils().showToast("Bluetooth on");
          scanDevices();
          break;
        case BluetoothState.off:
          Utils().showToast("Bluetooth off");
          enableBT();
          break;

        default:
      }
    });
  }

  Future<void> enableBT() async {
    BluetoothEnable.enableBluetooth.then((value) {
      print(value);
    });
  }

  void scanDevices() {
    providerGraphDataWatch!.setLoading(true);

    this.flutterBlue.scanResults.listen((List<ScanResult> results) {
      // printLog("  scan result length devices ${results.length}");
      providerGraphDataWatch!.devicesList.clear();
      for (ScanResult result in results) {
        // printLog("  scanResults ${result.device}");
        if (result.device.name.toLowerCase().contains(displayDeviceString)) {
          providerGraphDataWatch!.setDeviceList(result.device);
        }
      }
    });
    providerGraphDataWatch!.setLoading(false);

    this.flutterBlue.startScan();
    providerGraphDataWatch!.setIsScanning(true);
  }

  void connectDevice(BluetoothDevice device) async {
    providerGraphDataWatch!.setLoading(true);

    await this.flutterBlue.stopScan();
    providerGraphDataWatch!.setIsScanning(false);

    try {
      await device.connect(autoConnect: false).timeout(Duration(seconds: 5), onTimeout: () {
        device.disconnect();
        providerGraphDataWatch!.setLoading(false);
        chechBluetooth();
      });
    } catch (e) {
      printLog("Exception ${e.toString()}");
      providerGraphDataWatch!.setLoading(false);
    } finally {
      List<BluetoothService> services = [];
      services = await device.discoverServices();

      print("discoverd values");
      providerGraphDataWatch!.setConnectedDevice(device, context, services);
      Future.delayed(Duration(milliseconds: 200));
      readCharacteristics();
      providerGraphDataWatch!.setLoading(false);
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => WillPopScope(onWillPop: () => Future.value(false),child: Choice()));
    }
  }

  void readCharacteristics() {
    if (providerGraphDataWatch!.services != null &&
        providerGraphDataWatch!.services!.length > 0) {
      for (BluetoothService service in providerGraphDataWatch!.services!) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() == writeChangeModeUuid) {
            try {
              providerGraphDataWatch!
                  .setWriteChangeModeCharacteristic(characteristic);
            } catch (err) {
              printLog(
                  "setWriteChangeModeCharacteristic caught err ${err.toString()}");
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
            providerGraphDataWatch!.setReadCharacteristic(characteristic);
          }
        }
      }
    }
  }

  Dialog Choice() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 180,
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 30,
                    child: GestureDetector(child: Icon(Icons.close,color: clrWhite),onTap: (){
                      Navigator.pop(context);
                      if (providerGraphDataWatch!.connectedDevice != null) {
                        providerGraphDataWatch!.connectedDevice!.disconnect();
                      }
                      chechBluetooth();
                    },),
                  ),
                ],
              ),
            ),
            Container(
              height: 74,
              width: 280,
              color: clrWhite,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Container(
                  height: 74,
                  width: 280,
                  child: Center(
                    child: Text(
                      ecgNppg,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                onTap: () {
                  choice = ecgNppg;
                  providerGraphDataWatch!.tabLength = 3;
                  providerGraphDataRead!.setIndex(0);
                  providerGraphDataRead!.setIsecgppgOrSpo2(false);
                  if (providerGraphDataWatch!.isecgSelected == true)
                    providerGraphDataWatch!.setecgSelected();
                  if (providerGraphDataWatch!.isecgppgSelected == false)
                    providerGraphDataWatch!.setecgppgSelected();
                  if (providerGraphDataWatch!.isppgSelected == true)
                    providerGraphDataWatch!.setppgSelected();
                  Navigator.pop(context);
                  providerGraphDataWatch!.writeChangeModeCharacteristic!
                      .write([4]);
                  bluetoothConnSub!.cancel();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GraphScreen(
                                title: appName,
                                dropdownValue: choice!,
                              ))).then((value) {
                    //setUpBluetooth();
                    chechBluetooth();
                    if (value != null) {
                      showToast("Your device has been disconnected");
                    }
                  });
                },
              ),
            ),
            Container(
              height: 2,
              color: Colors.grey,
            ),
            Container(
              height: 74,
              width: 280,
              color: clrWhite,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Container(
                  height: 74,
                  width: 280,
                  child: Center(
                    child: Text(
                      spo2,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                onTap: () {
                  choice = spo2;
                  providerGraphDataWatch!.tabLength = 1;
                  providerGraphDataRead!.setIndex(3);
                  providerGraphDataRead!.setIsecgppgOrSpo2(true);
                  if (providerGraphDataWatch!.isspo2Selected == false)
                    providerGraphDataWatch!.setspo2Selected();
                  Navigator.pop(context);
                  providerGraphDataWatch!.writeChangeModeCharacteristic!
                      .write([7]);
                  bluetoothConnSub!.cancel();

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GraphScreen(
                                title: appName,
                                dropdownValue: choice!,
                              ))).then((value) {
                    //setUpBluetooth();
                    chechBluetooth();
                    if (value != null) {
                      showToast("Your device has been disconnected");
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
