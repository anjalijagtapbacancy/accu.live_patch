// import 'dart:math';

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class LineChartPage extends StatefulWidget {
//   final List<double> graphData;
//   LineChartPage({Key? key, required this.graphData}) : super(key: key);

//   @override
//   _LineChartPageState createState() => _LineChartPageState();
// }

// class _LineChartPageState extends State<LineChartPage> {
//   List<Color> gradientColors = [
//     const Color(0xff23b6e6),
//     const Color(0xff02d39a),
//   ];

//   List<FlSpot> spotsListData = [];
//   bool showAvg = false;

//   @override
//   void initState() {
//     spotsListData.clear();
//     for (int i = 0; i < widget.graphData.length; i++) {
//       spotsListData.add(FlSpot(double.tryParse(i.toStringAsFixed(2)) ?? 0, widget.graphData[i]));
//     }
//     print("spotsListData: ${spotsListData.toList()}");

//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 1.1,
//       child: Container(
//         decoration: const BoxDecoration(
//             borderRadius: BorderRadius.all(
//               Radius.circular(18),
//             ),
//             color: Color(0xff232d37)),
//         child: Padding(
//           padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
//           child: LineChart(
//             mainData(),
//           ),
//         ),
//       ),
//     );
//   }

//   LineChartData mainData() {
//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         getDrawingHorizontalLine: (value) {
//           return FlLine(
//             color: const Color(0xff37434d),
//             strokeWidth: 1,
//           );
//         },
//         getDrawingVerticalLine: (value) {
//           return FlLine(
//             color: const Color(0xff37434d),
//             strokeWidth: 1,
//           );
//         },
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: SideTitles(showTitles: false),
//         topTitles: SideTitles(showTitles: false),
//         // index / time
//         bottomTitles: SideTitles(
//           showTitles: true,
//           // reservedSize: 22,
//           interval: widget.graphData.length / (widget.graphData.length),
//           getTextStyles: (context, value) =>
//               const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 13),
//           getTitles: (value) {
//             return value.toString();
//           },
//           margin: 8,
//         ),
//         // graph data
//         leftTitles: SideTitles(
//           showTitles: true,
//           interval: widget.graphData.reduce(max) / (widget.graphData.length),
//           getTextStyles: (context, value) => const TextStyle(
//             color: Color(0xff67727d),
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//           ),
//           getTitles: (value) {
//             print(
//                 "getTitles max: ${widget.graphData.reduce(max)} interval: ${widget.graphData.reduce(max) / (widget.graphData.length)}");
//             return value.toString();
//           },
//           reservedSize: 80,
//           margin: 8,
//         ),
//       ),
//       borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
//       minX: 0,
//       maxX: double.parse(widget.graphData.length.toString()),
//       minY: widget.graphData.reduce(min),
//       maxY: widget.graphData.reduce(max),
//       lineBarsData: [
//         LineChartBarData(
//           spots: spotsListData,
//           isCurved: true, // graph shape
//           colors: gradientColors,
//           barWidth: 1, //curve border width
//           isStrokeCapRound: true,
//           dotData: FlDotData(
//             show: false,
//           ),
//           belowBarData: BarAreaData(
//             show: true,
//             colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }
