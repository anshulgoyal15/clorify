import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';

class ColorDetector extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ColorDetector();
  }
}

class _ColorDetector extends State<ColorDetector> {
  Color _col = Colors.black;
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: Text(
                    'blue:${_col.blue} red:${_col.red} green:${_col.green}'),
              ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.zoom_in),
          onPressed: () async {
            File image =
                await ImagePicker.pickImage(source: ImageSource.camera);
            setState(() {
              _loading = true;
            });
            final color = await PaletteGenerator.fromImageProvider(
                FileImage(image),
                maximumColorCount: 1);
            Color col = color.colors.toList()[0];
            setState(() {
              _col = col;
              _loading = false;
            });
          },
        ),
      ),
    );
  }
}
