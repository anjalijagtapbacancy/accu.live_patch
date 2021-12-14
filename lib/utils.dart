import 'package:flutter/material.dart';

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
}
