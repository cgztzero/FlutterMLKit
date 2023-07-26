import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera/page/scan/scan_code_result_page.dart';

import 'qrcode_scan_view.dart';

///function:
///@author:zhangteng
///@date:2023/7/21
class ScanCodePage extends StatefulWidget {
  const ScanCodePage({Key? key}) : super(key: key);

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  final GlobalKey<ScanQRCodeViewState> _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan code'),
      ),
      body: ScanQRCodeView(
        key: _globalKey,
        onCodeList: (List<String> codeList) {
          for (var code in codeList) {
            debugPrint('扫码结果:$code');
          }
          _pushResultPage(codeList[0]);
        },
      ),
    );
  }

  void _pushResultPage(String code)async{
    await Navigator.push(context, CupertinoPageRoute(builder: (cxt) {
      return ScanCodeResultPage(
        code: code,
      );
    }));
    _globalKey.currentState?.resumePreview();
  }
}
