import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  displayLocDialog(BuildContext context, String msg) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Please enable location service"),
          actions: [
            TextButton(
                onPressed: () {
                  // providerGraphDataWatch!.enableLocation();
                  Navigator.pop(context);
                },
                child: Text("Allow")),
          ],
        );
      },
    );
  }

  showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
