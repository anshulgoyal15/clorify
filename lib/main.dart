import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '_home.dart';
import 'web_view.dart';

Future<Null> main() async {
  List<CameraDescription> cameras = await availableCameras();

  runApp(new MyApp(cameras));
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  MyApp(this.cameras);
  @override
  State<StatefulWidget> createState() {
    return _MyApp();
  }
}

class _MyApp extends State<MyApp> {
  Color _color = Colors.red.withOpacity(.3);
  List<CameraDescription> camera;
  @override
  void initState() {
    camera = widget.cameras;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tflite real-time detection',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: Stack(
        children: <Widget>[
          HomePage(camera, (Color color) {
            setState(() {
              _color = color;
            });
          }),
          IgnorePointer(
            child: Container(
              color: _color,
            ),
          )
        ],
      ),
    );
  }
}
