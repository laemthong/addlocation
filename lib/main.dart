import 'package:flutter/material.dart';
import 'package:flutter_application_1/addlocation.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AddLocationPage(),
    );
  }
}
