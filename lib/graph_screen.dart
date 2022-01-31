import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bluetooth_connection/provider_graph_data.dart';
import 'dart:io';
import 'dart:math';
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
  _GraphScreenState(this.dropDownValue);

  var sub;
  String? dropDownValue;

  ProviderGraphData? providerGraphDataRead;
  ProviderGraphData? providerGraphDataWatch;
  String? type;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription? bluetoothConnSub;
  StreamSubscription? connDeviceSub;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
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
          if (scaffoldKey.currentState!.isDrawerOpen == true)
            Navigator.pop(context);
          if (scaffoldKey.currentState!.isEndDrawerOpen == true)
            Navigator.pop(context);
          Navigator.pop(context, true);
        }
      });
    });
  }

  @override
  void dispose() {
    if (providerGraphDataWatch!.connectedDevice != null) {
      providerGraphDataWatch!.connectedDevice!.disconnect();
    }
    bluetoothConnSub!.cancel();
    connDeviceSub!.cancel();
    providerGraphDataWatch!.setisFirst(true);
    providerGraphDataWatch!.clearProviderGraphData();
    super.dispose();
  }

  void openEndDrawer() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    providerGraphDataWatch = context.watch<ProviderGraphData>();

    return DefaultTabController(
      length: providerGraphDataWatch!.tabLength,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: clrDarkBg,
        appBar: AppBar(
          actions: [
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
                      //providerGraphDataWatch!.writeChangeModeCharacteristic!.write([0]);
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
                      sub = providerGraphDataWatch!.readCharacteristic!.value
                          .listen((value) {
                        readCharacteristics(value);
                      });
                      // start service
                      //providerGraphDataWatch!.writeChangeModeCharacteristic!.write([1]);
                      providerGraphDataWatch!.writeCharacteristic!.write([1]);
                      printLog("start service");
                      providerGraphDataWatch!.setServiceStarted(true);
                      providerGraphDataWatch!.setLoading(false);
                    }
                  }
                },
                child: providerGraphDataWatch!.isServiceStarted
                    ? Image.asset(
                        "assets/images/icons_circled_pause.png",
                        fit: BoxFit.fill,
                      )
                    : Image.asset(
                        "assets/images/icons_circled_play.png",
                        fit: BoxFit.fill,
                      ),
              ),
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
              visible: providerGraphDataWatch!.isEnabled &&
                  !providerGraphDataWatch!.isecgppgOrSpo2,
              child: TextButton(
                  onPressed: () async {
                    openEndDrawer();
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
                                  text: '$strStepCount\n',
                                  style:
                                      TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.stepCount == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.stepCount.round().toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '   steps',
                                  style: TextStyle(
                                      fontSize: 12, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.heartRate == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.heartRate.round().toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '   $heartRateUnit',
                                  style: TextStyle(
                                      fontSize: 12, color: clrPrimary),
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
                                  text: 'BP\n',
                                  style:
                                      TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.dBp == 0
                                    ? TextSpan(
                                        text: '--/',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.dBp.round().toString()}/',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      ),
                                providerGraphDataWatch!.dDbp == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.dDbp.round().toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 40,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '   $bpUnit',
                                  style: TextStyle(
                                      fontSize: 12, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.BpFromRt == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.BpFromRt.round().toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '   $bpUnit',
                                  style: TextStyle(
                                      fontSize: 12, color: clrPrimary),
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
                                  text: 'RR\n',
                                  style:
                                      TextStyle(fontSize: 15, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgPeak == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text:
                                            '${providerGraphDataWatch!.avgPeak.toStringAsFixed(4)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 50,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '',
                                  style: TextStyle(
                                      fontSize: 12, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgHrv == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.avgHrv
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgPrv == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.avgPrv
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.avgPTT == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.avgPTT
                                            .toStringAsFixed(4),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  $rvUnit',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.PP == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.PP
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  $bpUnit',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.MAP == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.MAP
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  $bpUnit',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.SV == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.SV
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  mL',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                                  style:
                                      TextStyle(fontSize: 14, color: clrWhite),
                                ),
                                providerGraphDataWatch!.CO == 0
                                    ? TextSpan(
                                        text: '--',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      )
                                    : TextSpan(
                                        text: providerGraphDataWatch!.CO
                                            .round()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: clrPrimary),
                                      ),
                                TextSpan(
                                  text: '  L/min',
                                  style: TextStyle(
                                      fontSize: 10, color: clrPrimary),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                      child: GestureDetector(
                        child: RaisedButton(
                          elevation: 5,
                          color: clrWhite,
                          child: Text(
                            'Disconnect',
                            style: TextStyle(
                                color: clrPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ),
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
                  selected: providerGraphDataWatch!.isecgppgSelected,
                  selectedTileColor: clrGrey,
                  leading: Image.asset(
                    "assets/images/line_graph.png",
                    height: 20,
                  ),
                  title: Text(
                    ecgNppg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(0);
                    Navigator.pop(context);
                    if (providerGraphDataWatch!.isecgppgSelected == false)
                      providerGraphDataWatch!.setecgppgSelected();

                    if (providerGraphDataWatch!.isspo2Selected == true)
                      providerGraphDataWatch!.setspo2Selected();
                    if (providerGraphDataWatch!.isecgSelected == true)
                      providerGraphDataWatch!.setecgSelected();
                    if (providerGraphDataWatch!.isppgSelected == true)
                      providerGraphDataWatch!.setppgSelected();
                  },
                ),
              ),
              Visibility(
                visible: !providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  selected: providerGraphDataWatch!.isecgSelected,
                  selectedTileColor: clrGrey,
                  leading: Image.asset(
                    "assets/images/line_graph.png",
                    height: 20,
                  ),
                  title: Text(
                    ecg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(1);
                    Navigator.pop(context);
                    if (providerGraphDataWatch!.isecgSelected == false)
                      providerGraphDataWatch!.setecgSelected();

                    if (providerGraphDataWatch!.isspo2Selected == true)
                      providerGraphDataWatch!.setspo2Selected();
                    if (providerGraphDataWatch!.isecgppgSelected = true)
                      providerGraphDataWatch!.setecgppgSelected();
                    if (providerGraphDataWatch!.isppgSelected = true)
                      providerGraphDataWatch!.setppgSelected();
                  },
                ),
              ),
              Visibility(
                visible: !providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  selected: providerGraphDataWatch!.isppgSelected,
                  selectedTileColor: clrGrey,
                  leading: Image.asset(
                    "assets/images/line_graph.png",
                    height: 20,
                  ),
                  title: Text(
                    ppg,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    providerGraphDataWatch!.setIndex(2);
                    Navigator.pop(context);
                    if (providerGraphDataWatch!.isppgSelected == false)
                      providerGraphDataWatch!.setppgSelected();

                    if (providerGraphDataWatch!.isspo2Selected == true)
                      providerGraphDataWatch!.setspo2Selected();
                    if (providerGraphDataWatch!.isecgSelected == true)
                      providerGraphDataWatch!.setecgSelected();
                    if (providerGraphDataWatch!.isecgppgSelected = true)
                      providerGraphDataWatch!.setecgppgSelected();
                  },
                ),
              ),
              Visibility(
                visible: providerGraphDataWatch!.isecgppgOrSpo2,
                child: ListTile(
                  selected: providerGraphDataWatch!.isspo2Selected,
                  selectedTileColor: clrGrey,
                  leading: Image.asset(
                    "assets/images/o2.png",
                    height: 30,
                  ),
                  title: Text(
                    spo2,
                    style: TextStyle(color: clrBlack),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (providerGraphDataWatch!.isspo2Selected == false)
                      providerGraphDataWatch!.setspo2Selected();

                    if (providerGraphDataWatch!.isecgSelected == true)
                      providerGraphDataWatch!.setecgSelected();
                    if (providerGraphDataWatch!.isecgppgSelected == true)
                      providerGraphDataWatch!.setecgppgSelected();
                    if (providerGraphDataWatch!.isppgSelected == true)
                      providerGraphDataWatch!.setppgSelected();
                  },
                ),
              ),
              Visibility(
                visible: (!providerGraphDataWatch!.isServiceStarted &&
                    !providerGraphDataWatch!.isecgppgOrSpo2),
                // visible: false,
                child: ListTile(
                  leading: Image.asset(
                    "assets/images/filter.png",
                    height: 30,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        "Filter",
                        style: TextStyle(color: clrBlack),
                      ),
                      Switch(
                        value: providerGraphDataWatch!.isEnabled ? true : false,
                        onChanged: (value) {
                          providerGraphDataWatch!.setIsEnabled();
                        },
                      )
                    ],
                  ),
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
    if (providerGraphDataWatch!.services != null &&
        providerGraphDataWatch!.services!.length > 0) {
      try {
        if (providerGraphDataWatch!.isServiceStarted) {
          if (providerGraphDataWatch!.tabLength == 3) {
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
    }
  }

  Stack _ecgPpgView() {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(top: 8, right: 8),
          children: <Widget>[
            rowTitle(ecg),
            graphWidget(ecg),
            rowTitle(ppg),
            graphWidget(ppg)
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: clrWhite,
                size: 20,
              ),
            ),
            onTap: () {
              openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Widget rowTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 1, 20, 0),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
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
                        providerGraphDataWatch!.tempEcgDecimalList, true)
                    : mainData(providerGraphDataWatch!.tempPpgSpotsListData,
                        providerGraphDataWatch!.tempPpgDecimalList, false),
                swapAnimationDuration: Duration.zero,
                swapAnimationCurve: Curves.linear),
          ),
        ),
      ),
    );
  }

  LineChartData mainData(
      List<FlSpot> tempSpotsList, List<num> tempDecimalList, bool isgrid) {
    return LineChartData(
      axisTitleData: FlAxisTitleData(
          show: true,
          bottomTitle: AxisTitle(
              margin: 0,
              showTitle: true,
              titleText: 'sec(s)',
              textStyle: TextStyle(fontSize: 12, color: clrWhite)),
          leftTitle: AxisTitle(
              showTitle: true,
              titleText: 'ADC values(mV)',
              textStyle: TextStyle(fontSize: 12, color: clrWhite))),
      gridData: FlGridData(
        show: isgrid,
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
              ? ((tempDecimalList.reduce(max) - tempDecimalList.reduce(min)) /
                              4)
                          .floorToDouble() !=
                      0
                  ? double.parse((((tempDecimalList.reduce(max) -
                                  tempDecimalList.reduce(min)) /
                              4)
                          .floor())
                      .toStringAsFixed(1))
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
      minX: tempSpotsList.isNotEmpty
          ? tempSpotsList.length < 500
              ? 0.225
              : tempSpotsList.first.x
          : 0,
      maxX: tempSpotsList.isNotEmpty
          ? tempSpotsList.length < 500
              ? 2.5
              : tempSpotsList.last.x
          : 0,
      minY: tempDecimalList.isNotEmpty
          ? tempSpotsList.length < 500
              ? 2
              : double.parse(
                  ((tempDecimalList.reduce(min)) - 0.2).toStringAsFixed(1))
          : 0,
      maxY: tempDecimalList.isNotEmpty
          ? tempSpotsList.length < 500
              ? 7
              : double.parse(
                  ((tempDecimalList.reduce(max)) + 0.2).toStringAsFixed(1))
          : 0,
      lineBarsData: [
        LineChartBarData(
          spots: tempSpotsList,
          show: true,
          curveSmoothness: 0.05,
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
            rowTitle(ecg),
            AspectRatio(
              aspectRatio: 3 / (1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
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
                            providerGraphDataWatch!.tempEcgDecimalList, true),
                        swapAnimationDuration: Duration.zero,
                        swapAnimationCurve: Curves.linear),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: clrWhite,
                size: 20,
              ),
            ),
            onTap: () {
              openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Widget _ppgTabView() {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(top: 8, right: 8),
          children: [
            rowTitle(ppg),
            AspectRatio(
              aspectRatio: 3 / (1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(18),
                      ),
                      color: clrDarkBg),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 0.0, top: 5, bottom: 45),
                    child: LineChart(
                        mainData(providerGraphDataWatch!.tempPpgSpotsListData,
                            providerGraphDataWatch!.tempPpgDecimalList, false),
                        swapAnimationDuration: Duration.zero,
                        swapAnimationCurve: Curves.linear),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: clrWhite,
                size: 20,
              ),
            ),
            onTap: () {
              openEndDrawer();
            },
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
                      style: TextStyle(fontSize: 32),
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
    String csvData = ListToCsvConverter().convert(column);
    final String directory = (await getApplicationSupportDirectory()).path;
    final path = "$directory/csv_graph_data.csv";
    printLog(path);
    final File file = File(path);
    await file.writeAsString(csvData);
    providerGraphDataWatch!.setLoading(false);

    Share.shareFiles(['${file.path}'], text: 'Exported csv');
  }
}
