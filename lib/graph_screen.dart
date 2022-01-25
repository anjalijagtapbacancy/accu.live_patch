import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/discover_devices_screen.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_connection/constant.dart';
import 'package:flutter_bluetooth_connection/progressbar.dart';
import 'package:flutter_bluetooth_connection/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'constant.dart';

class GraphScreen extends StatefulWidget {
  GraphScreen({Key? key, required this.title, required this.dropdownValue})
      : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  String dropdownValue;

  @override
  _GraphScreenState createState() => _GraphScreenState(dropdownValue);
}

class _GraphScreenState extends State<GraphScreen>
    with Constant, Utils, SingleTickerProviderStateMixin {
  // TabController? _controller;
  _GraphScreenState(this.dropDownValue);

  var sub;
  String? dropDownValue;

  ProviderGraphData? providerGraphDataRead;
  ProviderGraphData? providerGraphDataWatch;
  String? type;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription? bluetoothConnSub;
  StreamSubscription? connDeviceSub;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    //landscape();
    // Create TabController for getting the index of current tab
    /*  _controller = TabController(
        length: providerGraphDataWatch != null ? providerGraphDataWatch!.tabLength :  3, vsync: this);
    _controller!.addListener(() {
      providerGraphDataWatch!.setTabSelectedIndex(_controller!.index);
      printLog("-------Selected Index: " + _controller!.index.toString());
    });
*/
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      providerGraphDataRead = context.read<ProviderGraphData>();
      bluetoothConnSub = flutterBlue.state.listen((event) {
        switch (event) {
          case BluetoothState.on:
            break;
          case BluetoothState.off:
            showToast("Bluettoth off");
            providerGraphDataRead!.clearConnectedDevice();
            bluetoothConnSub!.cancel();
            connDeviceSub!.cancel();
            Navigator.pop(context, true);
            break;

          default:
        }
      });

      connDeviceSub =
          providerGraphDataRead!.connectedDevice!.state.listen((event) async {
        showToast("device event ${event.toString()}");
        if (event == BluetoothDeviceState.disconnected) {
          providerGraphDataRead!.clearConnectedDevice();
          bluetoothConnSub!.cancel();
          connDeviceSub!.cancel();
          if (_scaffoldKey.currentState!.isDrawerOpen == true)
            Navigator.pop(context);
          if (_scaffoldKey.currentState!.isEndDrawerOpen == true)
            Navigator.pop(context);
          Navigator.pop(context, true);
        }
      });
    });
  }

  @override
  void dispose() {
    //_controller!.dispose();
    if (providerGraphDataWatch!.connectedDevice != null) {
      providerGraphDataWatch!.connectedDevice!.disconnect();
    }
    bluetoothConnSub!.cancel();
    connDeviceSub!.cancel();
    providerGraphDataWatch!.setisFirst(true);
    providerGraphDataWatch!.clearProviderGraphData();
    super.dispose();
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    providerGraphDataWatch = context.watch<ProviderGraphData>();

    return DefaultTabController(
      length: providerGraphDataWatch!.tabLength,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: clrDarkBg,
        appBar: AppBar(
          // title: Text(
          //   widget.title,
          //   style: TextStyle(color: clrWhite),
          // ),
          actions: [
            //       Visibility(
            //         visible: !(providerGraphDataWatch!.connectedDevice != null),
            //         // visible: false,
            //         child: IconButton(
            //             icon: Icon(
            //               // providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
            //               providerGraphDataWatch!.isShowAvailableDevices ? Icons.bluetooth_disabled : Icons.bluetooth_audio,
            //               color: clrWhite,
            //             ),
            //             onPressed: () async{
            //               if (!providerGraphDataWatch!.isLoading) {
            // await device.disconnect();

            //               }
            //             }),
            //       ),
            //
            // Visibility(
            //   visible: !(providerGraphDataWatch!.connectedDevice != null),
            //   // visible: false,
            //   child: IconButton(
            //       icon: Icon(
            //         // providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
            //         providerGraphDataWatch!.isShowAvailableDevices
            //             ? Icons.bluetooth_disabled
            //             : Icons.bluetooth_audio,
            //         color: clrWhite,
            //       ),
            //       onPressed: () {
            //         if (!providerGraphDataWatch!.isLoading) {
            //           providerGraphDataWatch!.setIsShowAvailableDevices();
            //         }
            //       }),
            // ),
            // Visibility(
            //   visible: (!providerGraphDataWatch!.isServiceStarted),
            //   // visible: false,
            //   child: TextButton(
            //       child: Text(
            //         providerGraphDataWatch!.isEnabled ? "Disable" : "Enable",
            //         style: TextStyle(color: clrWhite),
            //       ),
            //       onPressed: () {
            //         if (!providerGraphDataWatch!.isLoading) {
            //           //widget.flutterBlue.startScan();
            //           providerGraphDataWatch!.setIsEnabled();
            //         }
            //       }),
            // ),
            Visibility(
              visible: providerGraphDataWatch!.connectedDevice != null,
              child: TextButton(
                  onPressed: () async {
                    if (!providerGraphDataWatch!.isLoading) {
                      //try {
                      print(
                          "UUID== ${providerGraphDataWatch!.readCharacteristic!.uuid.toString()}");
                      if (providerGraphDataWatch!.isServiceStarted) {
                        try {
                          await providerGraphDataWatch!.readCharacteristic!
                              .setNotifyValue(false);
                        } catch (err) {
                          printLog("notfy err ${err.toString()}");
                        }
                        providerGraphDataWatch!.setisFirst(true);
                        providerGraphDataWatch!.setLoading(true);
                        printLog("stop service");

                        //stop service
                        //providerGraphDataWatch!.writeCharacteristic!.write([0]);
                        providerGraphDataWatch!.writeCharacteristic!.write([0]);
                        if (sub != null) {
                          sub.cancel();
                        }
                        providerGraphDataWatch!.setServiceStarted(false);

                        await providerGraphDataWatch!.storedDataToLocal();

                        providerGraphDataWatch!.setLoading(false);
                      } else {
                        await providerGraphDataWatch!.readCharacteristic!
                            .setNotifyValue(true);

                        providerGraphDataWatch!.setLoading(true);

                        await providerGraphDataWatch!.clearStoreDataToLocal();
                        // printLog(
                        //     "mainEcgDecimalList.length=== ${providerGraphDataWatch!.mainEcgDecimalList.length}");
                        // printLog(
                        //     "mainPpgDecimalList.length=== ${providerGraphDataWatch!.mainPpgDecimalList.length}");
                        sub = providerGraphDataWatch!.readCharacteristic!.value
                            .listen((value) {
                          readCharacteristics(value);
                        });
                        // start service
                        //providerGraphDataWatch!.writeCharacteristic!.write([1]);
                        providerGraphDataWatch!.writeCharacteristic!.write([1]);
                        printLog("start service");
                        // ignore: cancel_subscriptions
                        // if (sub != null) {
                        //   sub.cancel();
                        // }

                        providerGraphDataWatch!.setServiceStarted(true);
                        providerGraphDataWatch!.setLoading(false);

                        // await providerGraphDataWatch!.readCharacteristic!
                        //     .read();
                      }
                      // } catch (e) {
                      //   printLog("err $e");
                      // }
                    }
                  },
                  child: Text(
                    providerGraphDataWatch!.isServiceStarted ? "Stop" : "Start",
                    style: TextStyle(color: clrWhite),
                  )),
            ),
            Visibility(
              visible: !providerGraphDataWatch!.isServiceStarted &&
                  providerGraphDataWatch!.tempEcgDecimalList.isNotEmpty,
              child: IconButton(
                  icon: Icon(Icons.share, color: clrWhite),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      _generateCsvFile();
                    }
                  }),
            ),
            Visibility(
              visible: providerGraphDataWatch!.isEnabled && !providerGraphDataWatch!.isecgppgOrSpo2,
              child: TextButton(
                  onPressed: () async {
                    _openEndDrawer();
                  },
                  child: Text(
                    'More',
                    style: TextStyle(color: clrWhite),
                  )),
            ),
          ],
          toolbarHeight: 40,
        ),
        body: Stack(
          children: [
            (providerGraphDataWatch!.connectedDevice != null)
                ? showBody()
                : providerGraphDataWatch!.isLoading
                    ? ProgressBar()
                    : Offstage(),
          ],
        ),
        endDrawer: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: clrDarkBg,
          ),
          child: Visibility(
            visible: providerGraphDataWatch!.isEnabled,
            child: Container(
              width: 400,
              child: Drawer(
                  child: SingleChildScrollView(
                    child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                    Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$strStepCount\n',
                                  style: TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.stepCount==0 ?
                                TextSpan(
                                  text:
                                  '--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                      '${providerGraphDataWatch!.stepCount.round().toString()}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '   steps',
                                  style: TextStyle(fontSize: 12, color: clrPrimary),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$strHeartRate\n',
                                  style: TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.heartRate==0 ?
                                TextSpan(
                                  text:
                                  '--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                      '${providerGraphDataWatch!.heartRate.round().toString()}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '   $heartRateUnit',
                                  style: TextStyle(fontSize: 12, color: clrPrimary),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '         BP\n',
                                    style: TextStyle(fontSize: 15, color: clrWhite),
                                  ),
                                  providerGraphDataWatch!.dBp==0 ?
                                  TextSpan(
                                    text:
                                    '--/',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50,
                                        color: clrPrimary),
                                  ):TextSpan(
                                    text:
                                        '${providerGraphDataWatch!.dBp.round().toString()}/',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50,
                                        color: clrPrimary),
                                  ),
                                  providerGraphDataWatch!.dDbp==0 ?
                                  TextSpan(
                                    text:
                                    '--',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 50,
                                        color: clrPrimary),
                                  ):TextSpan(
                                    text:
                                        '${providerGraphDataWatch!.dDbp.round().toString()}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        color: clrPrimary),
                                  ),
                                  TextSpan(
                                    text: '   $bpUnit',
                                    style:
                                        TextStyle(fontSize: 12, color: clrPrimary),
                                  )
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 20,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$strBpRt\n',
                                  style: TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.BpFromRt==0 ?
                                TextSpan(
                                  text:
                                  '--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                      '${providerGraphDataWatch!.BpFromRt.round().toString()}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '   $bpUnit',
                                  style: TextStyle(fontSize: 12, color: clrPrimary),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Arrhythmia Type\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.arrhythmia_type != null
                                    ? TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.arrhythmia_type}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: 'No Type Available',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'HRV\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgHrv==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.avgHrv.round().toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'PRV\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgPrv==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.avgPrv
                                      .round()
                                      .toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'PTT\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                              providerGraphDataWatch!.avgPTT==0 ? TextSpan(
                                text:'--',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: clrPrimary),
                              ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.avgPTT
                                      .toStringAsFixed(4),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Pulse Pressure\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.PP==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.PP
                                      .round().toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  $bpUnit',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'MAP\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.MAP==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.MAP
                                      .round().toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  $bpUnit',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'SV\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.SV==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.SV
                                      .round().toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  mL',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'RR\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgPeak==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.avgPeak.toStringAsFixed(4),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'CO\n',
                                  style: TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.CO==0 ? TextSpan(
                                  text:'--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ):TextSpan(
                                  text:
                                  providerGraphDataWatch!.CO
                                      .round().toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: clrPrimary),
                                ),
                                TextSpan(
                                  text: '  L/min',
                                  style: TextStyle(fontSize: 10,
                                      color: clrPrimary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
                  )),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                margin: EdgeInsets.only(bottom: 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                          color: clrWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      providerGraphDataWatch!.connectedDevice == null
                          ? 'Device Id: '
                          : 'Device Id: ${providerGraphDataWatch!.connectedDevice!.id}',
                      style: TextStyle(color: clrWhite, fontSize: 12),
                    ),
                    GestureDetector(
                      child: Text(
                        'Disconnect',
                        style: TextStyle(
                            color: clrWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                ),
              ),
              Visibility(
                visible: !providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  leading: Icon(Icons.align_horizontal_left_rounded),
                  title: Text(
                    ecgNppg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(0);
                    Navigator.pop(context);
                  },
                ),
              ),
              Visibility(
                visible: !providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  leading: Icon(Icons.align_horizontal_left_rounded),
                  title: Text(
                    ecg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(1);
                    Navigator.pop(context);
                  },
                ),
              ),
              Visibility(
                visible: !providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  leading: Icon(Icons.align_horizontal_left_rounded),
                  title: Text(
                    ppg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(2);
                    Navigator.pop(context);
                  },
                ),
              ),
              Visibility(
                visible: providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  leading: Icon(Icons.air),
                  title: Text(
                    spo2,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Visibility(
                visible: (!providerGraphDataWatch!.isServiceStarted &&
                    !providerGraphDataWatch!.isecgppgOrSpo2),
                // visible: false,
                child: ListTile(
                  leading: Icon(Icons.article),
                  title: Text(
                    providerGraphDataWatch!.isEnabled ? "Disable" : "Enable",
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      //widget.flutterBlue.startScan();
                      providerGraphDataWatch!.setIsEnabled();
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showBody() {
    switch (providerGraphDataWatch!.index) {
      case 0:
        return _ecgPpgView();
      case 1:
        return _ecgTabView();
      case 2:
        return _ppgTabView();
      case 3:
        return _spo2TabView();
      default:
        return _ecgPpgView();
    }
  }

  void readCharacteristics(List<int> value) {
    //print("services ${providerGraphDataWatch!.services!.length.toString()}");
    if (providerGraphDataWatch!.services != null &&
        providerGraphDataWatch!.services!.length > 0) {
      try {
        if (providerGraphDataWatch!.isServiceStarted) {
          //print("isServiceStarted");
          if (providerGraphDataWatch!.tabLength == 3) {
            //print("tabLength  iff ${value.toString()}");
            // List<int> temp_value;
            // printLog("value.lengh1 ${value.length}");
            // if(value.length>102) {
            //   temp_value=value.getRange(0,102).toList();
            // }
            // else {
            //   temp_value = value;
            // }
            // printLog("temp_value.lengh2 ${temp_value.length}");
            if (!providerGraphDataWatch!.isFirst) {
              providerGraphDataWatch!.generateGraphValuesList(value);
            } else {
              print("isFirst ${providerGraphDataWatch!.isFirst}");
              print("value $value ");
            }
            providerGraphDataWatch!.setisFirst(false);
          } else {
            print("tabLength  else");
            if (!providerGraphDataWatch!.isFirst) {
              providerGraphDataWatch!.getSpo2Data(value);
            } else {
              print("isFirst ${providerGraphDataWatch!.isFirst}");
              print("value $value ");
            }
            providerGraphDataWatch!.setisFirst(false);
          }
        }
      } catch (err) {
        printLog(" caught err ${err.toString()}");
      }
      // for (BluetoothService service in providerGraphDataWatch!.services!) {
      //   for (BluetoothCharacteristic characteristic
      //   in service.characteristics) {
      //     if (characteristic.uuid.toString() == writeChangeModeUuid) {
      //       try {
      //         providerGraphDataWatch!
      //             .setWriteChangeModeCharacteristic(characteristic);
      //         // providerGraphDataWatch!.setTabSelectedIndex(_controller!.index);
      //       } catch (err) {
      //         printLog(
      //             "setWriteChangeModeCharacteristic caught err ${err.toString()}");
      //       }
      //     }
      //     if (characteristic.uuid.toString() == writeUuid) {
      //       try {
      //         providerGraphDataWatch!.setWriteCharacteristic(characteristic);
      //       } catch (err) {
      //         printLog("setWriteCharacteristic caught err ${err.toString()}");
      //       }
      //     }
      //     if (characteristic.uuid.toString() == readUuid) {
      //       printLog("readUUid matched ! ${readUuid.toString()}");
      //
      //     }
      //   }
      //}
    }
  }

  Stack _ecgPpgView() {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(top: 8, right: 8),
          children: <Widget>[
            rowEcgTitle(ecg),
            graphWidget(ecg),
            rowPpgTitle(ppg),
            graphWidget(ppg)
          ],
        ),
      ],
    );
  }

  Widget rowPpgTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget rowEcgTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 12),
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
          padding:
              const EdgeInsets.only(right: 10.0, left: 5.0, top: 10, bottom: 0),
          child: LineChart(
              title == ecg
                  ? mainData(providerGraphDataWatch!.tempEcgSpotsListData,
                      providerGraphDataWatch!.tempEcgDecimalList)
                  : mainData(providerGraphDataWatch!.tempPpgSpotsListData,
                      providerGraphDataWatch!.tempPpgDecimalList),
              swapAnimationDuration: Duration.zero,
              swapAnimationCurve: Curves.linear),
        ),
      ),
    );
  }

  LineChartData mainData(
      List<FlSpot> tempSpotsList, List<double> tempDecimalList) {
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
      clipData: FlClipData.all(),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        // index / time
        bottomTitles: SideTitles(
          showTitles: true,
          // reservedSize: 22,
          interval: xAxisInterval,
          getTextStyles: (context, value) => TextStyle(
              color: clrBottomTitles,
              fontWeight: FontWeight.bold,
              fontSize: 13),
          getTitles: (value) {
            return value.toString();
          },
          margin: 8,
        ),
        // graph data
        leftTitles: SideTitles(
          showTitles: true,
          interval: tempDecimalList.isNotEmpty
              ? (tempDecimalList.reduce(max) - tempDecimalList.reduce(min)) /
                          4 !=
                      0
                  ? (tempDecimalList.reduce(max) -
                          tempDecimalList.reduce(min)) /
                      4
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
      borderData: FlBorderData(
          show: true, border: Border.all(color: clrGraphLine, width: 1)),
      minX: tempSpotsList.isNotEmpty ? tempSpotsList.first.x : 0,
      maxX: tempSpotsList.isNotEmpty ? tempSpotsList.last.x + 1 : 0,
      minY: tempDecimalList.isNotEmpty ? tempDecimalList.reduce(min) : 0,
      maxY: tempDecimalList.isNotEmpty ? tempDecimalList.reduce(max) : 0,
      lineBarsData: [
        LineChartBarData(
          spots: tempSpotsList,
          show: true,
          isCurved: true,
          // graph shape
          colors: [clrPrimary, clrSecondary],
          barWidth: 1,
          //curve border width
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
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(top: 8, right: 8),
          children: [
            rowEcgTitle(ecg),
            AspectRatio(
              aspectRatio: 3 / (1),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: clrDarkBg),
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: 10.0, left: 5.0, top: 5, bottom: 45),
                  child: LineChart(
                      mainData(providerGraphDataWatch!.tempEcgSpotsListData,
                          providerGraphDataWatch!.tempEcgDecimalList),
                      swapAnimationDuration: Duration.zero,
                      swapAnimationCurve: Curves.linear),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ppgTabView() {
    return ListView(
      padding: EdgeInsets.only(top: 8, right: 8),
      children: [
        rowPpgTitle(ppg),
        AspectRatio(
          aspectRatio: 3 / (1),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: clrDarkBg),
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 10.0, left: 5.0, top: 5, bottom: 45),
              child: LineChart(
                  mainData(providerGraphDataWatch!.tempPpgSpotsListData,
                      providerGraphDataWatch!.tempPpgDecimalList),
                  swapAnimationDuration: Duration.zero,
                  swapAnimationCurve: Curves.linear),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spo2TabView() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/o_two_1.png",
            width: 145,
            // color: clrWhite,
          ),
          SizedBox(
            width: 38,
          ),
          providerGraphDataWatch!.spo2Val == 0
              ? providerGraphDataWatch!.isServiceStarted == true
                  ? Text(
                      'Checking....',
                      style:
                          TextStyle(fontSize: 32),
                    )
                  : Text(
                      '-- --  %',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: providerGraphDataWatch!.spo2Val.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 32),
                      ),
                      TextSpan(
                        text: ' %',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  void _generateCsvFile() async {
    providerGraphDataWatch!.setLoading(true);
    List<List<dynamic>> column = [];
    List<dynamic> row = [];

    row.add("ecg");
    row.add("ppg");
    row.add("rrIntervalList");
    column.add(row);

    await providerGraphDataWatch!.getStoredLocalData();

    for (int i = 0;
        i < providerGraphDataWatch!.savedEcgLocalDataList.length;
        i++) {
      row = [];
      row.add(providerGraphDataWatch!.savedEcgLocalDataList[i]);
      row.add(providerGraphDataWatch!.savedPpgLocalDataList[i]);
      if (i < providerGraphDataWatch!.savedIntervalList.length) {
        row.add(providerGraphDataWatch!.savedIntervalList[i]);
      }
      column.add(row);
    }
    // if (providerGraphDataWatch!.savedIntervalList.length ==
    //     providerGraphDataWatch!.savedEcgLocalDataList.length) {
    //   for (int i = 0;
    //       i < providerGraphDataWatch!.savedEcgLocalDataList.length;
    //       i++) {
    //     row = [];
    //     row.add(providerGraphDataWatch!.savedEcgLocalDataList[i]);
    //     row.add(providerGraphDataWatch!.savedPpgLocalDataList[i]);
    //     row.add(providerGraphDataWatch!.savedIntervalList[i]);
    //     column.add(row);
    //   }
    // } else if (providerGraphDataWatch!.savedIntervalList.length >
    //     providerGraphDataWatch!.savedEcgLocalDataList.length) {
    //   for (int i = 0;
    //       i < providerGraphDataWatch!.savedIntervalList.length;
    //       i++) {
    //     row = [];
    //     if (i <= providerGraphDataWatch!.savedEcgLocalDataList.length) {
    //       row.add(providerGraphDataWatch!.savedEcgLocalDataList[i]);
    //       row.add(providerGraphDataWatch!.savedPpgLocalDataList[i]);
    //     } else {
    //       //row.add([]);
    //      // row.add([]);
    //     }
    //     row.add(providerGraphDataWatch!.savedIntervalList[i]);
    //     column.add(row);
    //   }
    // } else if (providerGraphDataWatch!.savedIntervalList.length <
    //     providerGraphDataWatch!.savedEcgLocalDataList.length) {
    //   for (int i = 0;
    //       i < providerGraphDataWatch!.savedEcgLocalDataList.length;
    //       i++) {
    //     row = [];
    //     row.add(providerGraphDataWatch!.savedEcgLocalDataList[i]);
    //     row.add(providerGraphDataWatch!.savedPpgLocalDataList[i]);
    //     if (i >= providerGraphDataWatch!.savedIntervalList.length) {
    //       //row.add([]);
    //     } else {
    //       row.add(providerGraphDataWatch!.savedIntervalList[i]);
    //     }
    //     column.add(row);
    //   }
    // }

    // for(int i=0;i<providerGraphDataWatch!.savedIntervalList.length;i++){
    //   row = [];
    //   row.add(providerGraphDataWatch!.savedIntervalList[i]);
    //   column.add(row);
    // }
    //column.add(row);
    String csvData = ListToCsvConverter().convert(column);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/csv_graph_data.csv";
    printLog(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerGraphDataWatch!.setLoading(false);

    Share.shareFiles(['${file.path}'], text: 'Exported csv');

    /*for (int i = 0; i < providerGraphDataWatch!.peaksPositionsPpgArray.length; i++) {
      row = [];
      row.add(providerGraphDataWatch!.peaksPositionsPpgArray[i]);
      column.add(row);
    }

    String csvData = ListToCsvConverter().convert(column);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/peaksPositionsPpgArray.csv";
    printLog(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerGraphDataWatch!.setLoading(false);
    Share.shareFiles(['${file.path}'], text: 'peaksPositionsPpgArray csv');*/
  }
}
