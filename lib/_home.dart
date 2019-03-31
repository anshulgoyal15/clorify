import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:convert' as json;
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

import 'camera.dart';
import 'bndbox.dart';
import 'web_view.dart';
import 'detect.dart';

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class HomePage extends StatefulWidget {
  Function ch;
  final List<CameraDescription> cameras;

  HomePage(this.cameras, this.ch);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String color;
  Map colors = {
    'red': Colors.red.withOpacity(0.1),
    'blue': Colors.blue.withOpacity(0.1)
  };
  String _text = '';
  File _image;
  Future getImage(context) async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = image;
    });
    try {
      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(image);
      final TextRecognizer textRecognizer =
          FirebaseVision.instance.textRecognizer();
      final VisionText visionText =
          await textRecognizer.processImage(visionImage);
      setState(() {
        _text = visionText.text;
      });
    } catch (error) {
      print(error);
    }
  }

  SpeechRecognition _speech = new SpeechRecognition();
  FlutterTts controller = FlutterTts();
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";
  @override
  void initState() {
    super.initState();
    color = 'red';
  }

  loadModel() async {
    String res;
    switch (_model) {
      case yolo:
        res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
        break;
      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt");
        break;
    }
    print(res);
  }

  onSelect(model) async {
    setState(() {
      _model = model;
    });
    loadModel();
    await controller.setSpeechRate(.6);
    _speech.activate();
    _speech.setRecognitionStartedHandler(() {});
    _speech.setRecognitionResultHandler((String result) {});
    _speech.setRecognitionCompleteHandler(() {
      _speech.listen(locale: 'en_US').then((result) {
        if (result) {
          //controller.speak('Hi Man');
          _speech.stop().then((data) {
            Timer.periodic(Duration(seconds: 4), (Timer timer) {
              String dec = _recognitions[0]['detectedClass'];
              print('ssd');
              controller.speak('I saw $dec');
            });
          });
        }
      });
    });
    _speech.listen(locale: 'en_US').then((result) {
      if (result.toLowerCase() == 'color it') {
        //controller.speak('Hi Man');
        _speech.stop().then((data) {
          Timer.periodic(Duration(seconds: 4), (Timer timer) {
            String dec = _recognitions[0]['detectedClass'];
            print('ssd');
            controller.speak('I saw $dec');
          });
        });
      }
    });
  }

  setRecognitions(recognitions, imageHeight, imageWidth) async {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: Builder(
        builder: (BuildContext context) => FloatingActionButton(
            onPressed: () => getImage(context),
            tooltip: 'Pick Image',
            child: Icon(Icons.add_a_photo)),
      ),
      body: FutureBuilder(
          initialData: [],
          future: get('https://polar-lowlands-50474.herokuapp.com/liveUsers')
              .then((data) => json.json.decode(data.body)),
          builder: (BuildContext context, AsyncSnapshot snapshot) => Builder(
                builder: (BuildContext context) => Stack(children: <Widget>[
                      _model == ""
                          ? Center(
                              child: ListView(
                                padding: EdgeInsets.all(30.0),
                                children: <Widget>[
                                  Center(
                                    child: Text(
                                        'Number of users ${snapshot.data.length.toString() ?? "0"}'),
                                  ),
                                  Text(_text),
                                  _image != null
                                      ? Center(
                                          child: Image.file(_image),
                                        )
                                      : Container(),
                                  Container(child:DropdownButton<String>(
                                      value: color,
                                      onChanged: (String newValue) {
                                        setState(() {
                                          color = newValue;
                                        });
                                        widget.ch(colors[newValue]);
                                      },
                                      items: <String>['red', 'blue']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList())),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      RaisedButton(
                                        child: const Text(ssd),
                                        onPressed: () => onSelect(ssd),
                                      ),
                                      RaisedButton(
                                        child: const Text(yolo),
                                        onPressed: () => onSelect(yolo),
                                      ),
                                    ],
                                  ),
                                  RaisedButton(
                                      child: const Text(
                                          'Check Your Color Blindness'),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  Game()))),
                                  RaisedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  ColorDetector()));
                                    },
                                    child: Text('Detect Color'),
                                  )
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                Camera(
                                  widget.cameras,
                                  _model,
                                  setRecognitions,
                                ),
                                BndBox(
                                  _recognitions == null ? [] : _recognitions,
                                  math.max(_imageHeight, _imageWidth),
                                  math.min(_imageHeight, _imageWidth),
                                  screen.height,
                                  screen.width,
                                ),
                              ],
                            ),
                    ]),
              )),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
