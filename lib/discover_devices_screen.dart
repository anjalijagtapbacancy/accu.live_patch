import 'package:bluetooth_enable/bluetooth_enable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

class DiscoverDevices extends StatefulWidget {
  DiscoverDevices({Key? key}) : super(key: key);

  @override
  _DiscoverDevicesState createState() => _DiscoverDevicesState();
}

class _DiscoverDevicesState extends State<DiscoverDevices> with Constant {
  ProviderGraphData? providerGraphDataRead;
  ProviderGraphData? providerGraphDataWatch;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  var sub;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      providerGraphDataRead = context.read<ProviderGraphData>();
      setUpBluetooth();
    });
  }

  @override
  void dispose() {
    //_controller!.dispose();
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
                providerGraphDataWatch!.isScanning ? "Stop Scan" : "Scan",
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
                    await this.flutterBlue.startScan();
                  }
                }
              }),
          Visibility(
            visible: !(providerGraphDataWatch!.isBluetoothEnable),
            child: IconButton(
                icon: Icon(
                  Icons.bluetooth_connected,
                  color: clrWhite,
                ),
                onPressed: () {
                  if (!providerGraphDataWatch!.isLoading) {
                    // Request to turn on Bluetooth within an app
                    BluetoothEnable.enableBluetooth.then((value) {
                      if (value == "true") {
                        //Bluetooth has been enabled
                        providerGraphDataWatch!.setIsBluetoothEnable(true);
                        setUpBluetooth();
                      } else if (value == "false") {
                        //Bluetooth has not been enabled
                        providerGraphDataWatch!.setIsBluetoothEnable(false);
                      }
                    });
                  }
                }),
          ),
          SizedBox(width: 8)
        ],
      ),
      body: Stack(
        children: [
          ListView.separated(
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
                                  providerGraphDataWatch!.devicesList[i].name == ''
                                      ? '(unknown device)'
                                      : providerGraphDataWatch!.devicesList[i].name,
                                  style: TextStyle(color: clrWhite),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  providerGraphDataWatch!.devicesList[i].id.toString(),
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 200,
                          child: OutlinedButton(
                            style: TextButton.styleFrom(
                              side: BorderSide(color: clrWhite.withOpacity(0.4), width: 1),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                            ),
                            child: Text(
                              strConnect,
                              style: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.w500),
                            ),
                            onPressed: () async {
                              connectDevice(providerGraphDataWatch!.devicesList[i]);
                              providerGraphDataWatch!.TrainModelForType();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          providerGraphDataWatch!.isLoading ? ProgressBar() : Offstage(),
        ],
      ),
    );
  }

  void setUpBluetooth() {
    this.flutterBlue.isOn.then((value) {
      providerGraphDataWatch!.setIsBluetoothEnable(value);

      printLog("  isOn ${value.toString()}");
      if (value) {
        // BluetoothEnable.enableBluetooth.then((value) {
        //   if (value == "true") {
        //     //Bluetooth has been enabled
        //   } else if (value == "false") {
        //     //Bluetooth has not been enabled
        //   }
        // });

        this.flutterBlue.isAvailable.then((value) {
          printLog(" isAvailable ${value.toString()}");
        });

        this.flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
          printLog("  devices ${devices.length}");

          for (BluetoothDevice device in devices) {
            printLog("  connectedDevices ${device}");

            if (device.name.toLowerCase().contains(displayDeviceString)) {
              providerGraphDataWatch!.setDeviceList(device);
            }
          }
        });

        if (providerGraphDataWatch!.devicesList.length == 1) {
          print("devicesList iff ${providerGraphDataWatch!.devicesList.length.toString()}");
          connectDevice(providerGraphDataWatch!.devicesList.first);
        } else {
          print("devicesList elsee ${providerGraphDataWatch!.devicesList.length.toString()}");
        }

        this.flutterBlue.scanResults.listen((List<ScanResult> results) {
          printLog("  scan result length devices ${results.length}");
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => ScanResultTile(result: results.first,onTap: null)));
          for (ScanResult result in results) {
            printLog("  scanResults ${result.device}");
            if (result.device.name.toLowerCase().contains(displayDeviceString)) {
              providerGraphDataWatch!.setDeviceList(result.device);
            }
          }
        });

        this.flutterBlue.startScan();
        providerGraphDataWatch!.setIsScanning(true);
      }
    });
  }

  void connectDevice(BluetoothDevice device) async {
    providerGraphDataWatch!.setLoading(true);

    await this.flutterBlue.stopScan();
    providerGraphDataWatch!.setIsScanning(false);

    try {
      await device.connect();
      // print("IIII index  ${_controller!.index.toString()}");
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
}
