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

import 'ModelClass/Prediction.dart';
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

  @override
  void initState() {
    super.initState();

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
    providerGraphDataWatch!.clearProviderGraphData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    providerGraphDataWatch = context.watch<ProviderGraphData>();

    return DefaultTabController(
      length: providerGraphDataWatch!.tabLength,
      child: Scaffold(
        backgroundColor: clrDarkBg,
        appBar: AppBar(
          bottom: new PreferredSize(
              preferredSize: new Size(200.0, 20.0),
              child: new Container(
                height: 32.0,
                child: TabBar(
                  tabs: tabsChoice(providerGraphDataWatch!.tabLength),
                ),
              )),
          title: Text(
            widget.title,
            style: TextStyle(color: clrWhite),
          ),
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

            Visibility(
              visible: !(providerGraphDataWatch!.connectedDevice != null),
              // visible: false,
              child: IconButton(
                  icon: Icon(
                    // providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
                    providerGraphDataWatch!.isShowAvailableDevices
                        ? Icons.bluetooth_disabled
                        : Icons.bluetooth_audio,
                    color: clrWhite,
                  ),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      providerGraphDataWatch!.setIsShowAvailableDevices();
                    }
                  }),
            ),
            Visibility(
              visible: providerGraphDataWatch!.isServiceStarted &&
                  providerGraphDataWatch!.tempEcgDecimalList.isNotEmpty,
              // visible: false,
              child: TextButton(
                  child: Text(
                    providerGraphDataWatch!.isEnabled ? "Disabled" : "Enabled",
                    style: TextStyle(color: clrWhite),
                  ),
                  onPressed: () {
                    if (!providerGraphDataWatch!.isLoading) {
                      widget.flutterBlue.startScan();
                      providerGraphDataWatch!.setIsEnabled();
                    }
                  }),
            ),
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
              visible: false,
              child: Opacity(
                opacity: !providerGraphDataWatch!.isServiceStarted ? 1 : 0.4,
                child: DropdownButton<String>(
                  hint: Text(
                    dropDownValue!,
                    style: TextStyle(color: Colors.white),
                  ),
                  items: <String>[ecgNppg, spo2].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Opacity(
                        opacity: opacity(value),
                        child: GestureDetector(
                          child: Text(value),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: !providerGraphDataWatch!.isServiceStarted
                      ? (value) async {
                          print(value);
                          if (opacity(value!) == 1) {
                            providerGraphDataWatch!.setLoading(true);
                            print(providerGraphDataWatch!.isServiceStarted);
                            changeMode(value);
                            providerGraphDataWatch!.setLoading(false);
                            setState(() {
                              dropDownValue = value;
                            });
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
          toolbarHeight: 78,
        ),
        body: Stack(
          children: [
            (providerGraphDataWatch!.connectedDevice != null)
                ? TabBarView(
                    children: tabViews(providerGraphDataWatch!.tabLength),
                  )
                : providerGraphDataWatch!.isLoading
                    ? ProgressBar()
                    : Offstage(),
          ],
        ),
      ),
    );
  }

  void changeMode(String value) {
    if (value == ecgNppg) {
      providerGraphDataWatch!.tabLength = 3;
      providerGraphDataWatch!.writeChangeModeCharacteristic!.write([4]);
    } else {
      providerGraphDataWatch!.tabLength = 1;
      providerGraphDataWatch!.writeChangeModeCharacteristic!.write([7]);
    }
  }

  double opacity(String value) {
    if (value == dropDownValue) {
      return 0.4;
    } else {
      return 1;
    }
  }

  List<Widget> tabsChoice(int length) {
    if (length == 3) {
      return [_tabWidget(ecgNppg), _tabWidget(ecg), _tabWidget(ppg)];
    } else {
      return [_tabWidget(spo2)];
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
            providerGraphDataWatch!.generateGraphValuesList(value);
          } else {
            //print("tabLength  else ${value}");
            providerGraphDataWatch!.getSpo2Data(value);
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

  List<Widget> tabViews(int length) {
    if (length == 3) {
      return [_ecgPpgView(), _ecgTabView(), _ppgTabView()];
    } else {
      return [_spo2TabView()];
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
      padding: EdgeInsets.only(top: 4.0),
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
          Align(
            alignment: Alignment.centerRight,
            child: Visibility(
              visible: providerGraphDataWatch!.isEnabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'PTT: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.avgPTT
                                  .toStringAsFixed(4),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'BpRt:',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.BpFromRt.toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'HRV: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.avgHrv
                                  .round()
                                  .toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextSpan(
                              text: ' $rvUnit',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'PRV: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.avgPrv
                                  .round()
                                  .toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextSpan(
                              text: ' $rvUnit',
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'BP: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.dBp
                                  .round()
                                  .toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextSpan(
                              text: ' $bpUnit',
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'DBP: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextSpan(
                              text: providerGraphDataWatch!.dDbp
                                  .round()
                                  .toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextSpan(
                              text: ' $bpUnit',
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget rowEcgTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 4.0),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              providerGraphDataWatch!.arrhythmia_type != null
                  ? Text("Type: ${providerGraphDataWatch!.arrhythmia_type}")
                  : Text("Type: No Type Available"),
              // FutureBuilder<ArrhythmiaType>(
              //   future: providerGraphDataWatch!.arrhythmia_type,
              //   builder: (context, snapshot) {
              //     if (snapshot.hasData) {
              //       if (snapshot.data!.arrhythmiaType == "N") {
              //         type = "Normal";
              //       } else if (snapshot.data!.arrhythmiaType == "B") {
              //         type = "Bigeminy";
              //       } else if (snapshot.data!.arrhythmiaType == "VT") {
              //         type = "Ventricular Tachycardia";
              //       } else if (snapshot.data!.arrhythmiaType == "T") {
              //         type = "Trigeminy";
              //       }
              //       return Text(type ?? "");
              //     } else if (snapshot.hasError) {
              //       return Text('Exception');
              //     }
              //     return Text("No Type Available");
              //   },
              // ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Visibility(
                  visible: providerGraphDataWatch!.isEnabled
                  // &&
                  // providerGraphDataWatch!.heartRate < 150 &&
                  // providerGraphDataWatch!.heartRate > 60
                  ,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$strStepCount ',
                          style: TextStyle(fontSize: 12),
                        ),
                        TextSpan(
                          text: providerGraphDataWatch!.stepCount
                              .round()
                              .toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: ' steps',
                          style: TextStyle(fontSize: 12),
                        )
                      ],
                    ),
                  )),
            ),
          ),
          SizedBox(
            width: 8,
          ),
          Visibility(
              // visible: providerGraphDataWatch!.isEnabled,

              child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$strHeartRate ',
                  style: TextStyle(fontSize: 12),
                ),
                TextSpan(
                  text:
                      "${providerGraphDataWatch!.heartRate.round().toString()}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextSpan(
                  text: ' $heartRateUnit',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
          )),
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
          padding: const EdgeInsets.only(
              right: 18.0, left: 12.0, top: 24, bottom: 12),
          child: LineChart(title == ecg
              ? mainData(providerGraphDataWatch!.tempEcgSpotsListData,
                  providerGraphDataWatch!.tempEcgDecimalList)
              : mainData(providerGraphDataWatch!.tempPpgSpotsListData,
                  providerGraphDataWatch!.tempPpgDecimalList)),
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
                      right: 18.0, left: 12.0, top: 24, bottom: 12),
                  child: LineChart(mainData(
                      providerGraphDataWatch!.tempEcgSpotsListData,
                      providerGraphDataWatch!.tempEcgDecimalList)),
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
                  right: 18.0, left: 12.0, top: 24, bottom: 12),
              child: LineChart(mainData(
                  providerGraphDataWatch!.tempPpgSpotsListData,
                  providerGraphDataWatch!.tempPpgDecimalList)),
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
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: providerGraphDataWatch!.spo2Val.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
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
