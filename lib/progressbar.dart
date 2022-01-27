import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_connection/constant.dart';

class ProgressBar extends StatelessWidget with Constant {
  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: false,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black.withOpacity(0.26),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(clrPrimary)),
            ),
          ),
        ));
  }
}
