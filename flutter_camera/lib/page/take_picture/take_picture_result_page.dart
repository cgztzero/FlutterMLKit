import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

///function:
///@author:zhangteng
///@date:2023/7/20
class ImageResultPage extends StatelessWidget {
  final String path;

  const ImageResultPage({Key? key, required this.path}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image'),
      ),
      body: Center(
        child: Image.file(File(path)),
      ),
    );
  }
}
