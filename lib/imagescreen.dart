import 'dart:io';
import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final String filePath;
  const ImageScreen({
    Key key,
    this.filePath
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(filePath);
    Widget imageWidget;
    if(filePath == null) {
      imageWidget = new Text('Please take a photo');
    } else {
      imageWidget = new Image.file(new File(filePath));
    }
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Image Screen"),
      ),
      body: new Center(
        child: imageWidget,
      ),
    );
  }
}
