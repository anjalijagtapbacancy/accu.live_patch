// import 'package:bluetooth_enable/bluetooth_enable.dart';
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
    //_controller!.dispose();
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
                    //await this.flutterBlue.startScan();
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
                        // color: clrGrey,
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
              : Center(child: Text("No devices are available")),
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
          // if(providerGraphDataWatch!.isLocServiceEnabled)
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

//   void setUpBluetooth() {
//     this.flutterBlue.isOn.then((value) {
//       providerGraphDataWatch!.enableLocation();
//
//       printLog("  isOn ${value.toString()}");
//       if (!value) {
//         providerGraphDataWatch!.setLoading(true);
//
//         //Request to turn on Bluetooth within an app
//         // BluetoothEnable.enableBluetooth.then((value) {
//         //   providerGraphDataWatch!.setLoading(false);
//
//         //   if (value == "true") {
//         //     //Bluetooth has been enabled
//         //     // setUpBluetooth();
//         //   } else if (value == "false") {
//         //     //Bluetooth has not been enabled
//         //   }
//         // });
//       }
//       if (value) {
//         providerGraphDataWatch!.setLoading(true);
//
//         this.flutterBlue.isAvailable.then((value) {
//           printLog(" isAvailable ${value.toString()}");
//         });
//
//         /*this
//             .flutterBlue
//             .connectedDevices
//             .asStream()
//             .listen((List<BluetoothDevice> devices) {
//           printLog("  devices ${devices.length}");
//
//           for (BluetoothDevice device in devices) {
//             printLog("  connectedDevices ${device}");
//
//             if (device.name.toLowerCase().contains(displayDeviceString)) {
//               providerGraphDataWatch!.setDeviceList(device);
//               device.state.asBroadcastStream();
//             }
//           }
//         });*/
//
//         /*   if (providerGraphDataWatch!.devicesList.length == 1) {
//           print("devicesList iff ${providerGraphDataWatch!.devicesList.length.toString()}");
//           connectDevice(providerGraphDataWatch!.devicesList.first);
//         } else {
//           print("devicesList elsee ${providerGraphDataWatch!.devicesList.length.toString()}");
//         }
// */
//         this.flutterBlue.scanResults.listen((List<ScanResult> results) {
//           // printLog("  scan result length devices ${results.length}");
//           for (ScanResult result in results) {
//             // printLog("  scanResults ${result.device}");
//             if (result.device.name.toLowerCase().contains(displayDeviceString)) {
//               providerGraphDataWatch!.setDeviceList(result.device);
//             }
//           }
//         });
//         providerGraphDataWatch!.setLoading(false);
//
//         this.flutterBlue.startScan();
//         providerGraphDataWatch!.setIsScanning(true);
//       }
//     });
//   }

  void scanDevices() {
    // if(providerGraphDataWatch!=null) {
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
    //  }
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
      // print("IIII index  ${_controller!.index.toString()}");
    } catch (e) {
      // if (e.code != 'already_connected') {
      //   throw e;
      // }
      printLog("Exception ${e.toString()}");
      providerGraphDataWatch!.setLoading(false);
    } finally {
      List<BluetoothService> services = [];
      services = await device.discoverServices();

      print("discoverd values");
      providerGraphDataWatch!.setConnectedDevice(device, context, services);
      Future.delayed(Duration(milliseconds: 200));
      readCharacteristics();
      //providerGraphDataWatch!.TrainModel();
      providerGraphDataWatch!.setLoading(false);
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => Choice());

      // providerGraphDataWatch!.setIsShowAvailableDevices();
    }
  }

  void readCharacteristics() {
    //print("services ${providerGraphDataWatch!.services!.length.toString()}");
    if (providerGraphDataWatch!.services != null &&
        providerGraphDataWatch!.services!.length > 0) {
      for (BluetoothService service in providerGraphDataWatch!.services!) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() == writeChangeModeUuid) {
            try {
              providerGraphDataWatch!
                  .setWriteChangeModeCharacteristic(characteristic);
              // providerGraphDataWatch!.setTabSelectedIndex(_controller!.index);
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
            // try {
            providerGraphDataWatch!.setReadCharacteristic(characteristic);
            //   if (providerGraphDataWatch!.isServiceStarted) {
            //     if (providerGraphDataWatch!.tabLength == 3) {
            //       providerGraphDataWatch!.generateGraphValuesList(
            //           providerGraphDataWatch!.readValues[characteristic.uuid]);
            //     } else {
            //       providerGraphDataWatch!.getSpo2Data(
            //           providerGraphDataWatch!.readValues[characteristic.uuid]);
            //     }
            //   }
            // } catch (err) {
            //   printLog(" caught err ${err.toString()}");
            // }
          }
        }
      }
    }
  }

  Dialog Choice() {
    return Dialog(
      child: Container(
        height: 150,
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 74,
              width: 280,
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
      ), /* PopupMenuButton(
            onSelected: (value) {
              if (value == 1) {
                choice = ecgNppg;
                providerGraphDataWatch!.tabLength = 3;
              } else {
                choice = spo2;
                providerGraphDataWatch!.tabLength = 1;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage(
                            title: appName,
                            dropdownValue: choice!,
                          )));
            },
            itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(ecgNppg),
                    value: 1,
                  ),
                  PopupMenuItem(
                    child: Text(spo2),
                    value: 2,
                  )
                ]),*/
    );
  }
}
