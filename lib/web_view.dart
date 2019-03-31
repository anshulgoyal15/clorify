import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class Game extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: WebviewScaffold(
      url: 'https://clorify-testing.herokuapp.com/',
      initialChild: Container(),
    )
    );
  }
  
}