import 'package:flutter/material.dart';

///function:
///@author:zhangteng
///@date:2023/7/21
class ScanCodeResultPage extends StatelessWidget {
  final String code;

  const ScanCodeResultPage({Key? key, required this.code}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Code Result'),
      ),
      body: Center(
        child: Text(
          'Code result:$code',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    );
  }
}
