import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera/page/draw/draw_board_page.dart';
import 'package:flutter_camera/page/record/record_video_page.dart';
import 'package:flutter_camera/page/scan/scan_code_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'page/take_picture/take_picture_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Camera Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: ElevatedButton(
                  onPressed: () async {
                    bool isOK = await _requestCameraPermission();
                    if (!isOK) {
                      return;
                    }
                    Navigator.push(context, CupertinoPageRoute(builder: (cxt) {
                      return CameraPage();
                    }));
                  },
                  child: const Center(
                    child: Text('Easy Taking Picture'),
                  )),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                  onPressed: () async {
                    bool isOK = await _requestCameraPermission();
                    if (!isOK) {
                      return;
                    }
                    Navigator.push(context, CupertinoPageRoute(builder: (cxt) {
                      return RecordVideoPage();
                    }));
                  },
                  child: const Center(
                    child: Text('Easy Recording Video'),
                  )),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                  onPressed: () async {
                    bool isOK = await _requestCameraPermission();
                    if (!isOK) {
                      return;
                    }
                    Navigator.push(context, CupertinoPageRoute(builder: (cxt) {
                      return ScanCodePage();
                    }));
                  },
                  child: const Center(
                    child: Text('Easy Scanning QRCode'),
                  )),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status == PermissionStatus.granted) {
      return true;
    } else {
      status = await Permission.camera.request();
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }
}
