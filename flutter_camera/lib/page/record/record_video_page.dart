import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera/page/record/record_video_result_page.dart';

///function:record video
///@author:zhangteng
///@date:2023/7/24
class RecordVideoPage extends StatefulWidget {
  const RecordVideoPage({Key? key}) : super(key: key);

  @override
  State<RecordVideoPage> createState() => _RecordVideoPageState();
}

class _RecordVideoPageState extends State<RecordVideoPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('record video'),
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: CameraPreview(_controller!),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: _controller == null
          ? Container()
          : SizedBox(
              height: 300,
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FittedBox(
                      child: FloatingActionButton(
                        heroTag: Object(),
                        onPressed: () async {
                          if (!_controller!.value.isRecordingVideo) {
                            await _controller!.prepareForVideoRecording();
                            await _controller!.startVideoRecording();
                            setState(() {});
                            timerKey.currentState!.startTimer();
                          } else {
                            timerKey.currentState!.stopTimer();
                            XFile file = await _controller!.stopVideoRecording();
                            setState(() {});
                            if (file.path == '') {
                              return;
                            }
                            _pushToResultPage(file.path);
                          }
                        },
                        child: Text(
                          _controller!.value.isRecordingVideo ? 'stop' : 'record',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 15)),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FittedBox(
                      child: FloatingActionButton(
                        heroTag: Object(),
                        onPressed: () async {
                          if (!_controller!.value.isRecordingVideo) {
                            return;
                          }

                          if (_controller!.value.isRecordingPaused) {
                            _controller!.resumeVideoRecording();
                            timerKey.currentState!.resumeTimer();
                          } else {
                            _controller!.pauseVideoRecording();
                            timerKey.currentState!.pauseTimer();
                          }
                          setState(() {});
                        },
                        child: Text(_controller!.value.isRecordingPaused ? 'resume' : 'pause',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 15)),
                  TimerWidget(
                    key: timerKey,
                  )
                ],
              ),
            ),
    );
  }

  final GlobalKey<_TimerWidgetState> timerKey = GlobalKey();

  void _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _pushToResultPage(String path) async {
    _pausePreview();
    await Navigator.push(context, CupertinoPageRoute(builder: (cxt) {
      return RecordVideoResultPage(path: path);
    }));
    _resumePreview();
  }

  void _pausePreview() {
    _controller?.pausePreview();
  }

  void _resumePreview() {
    _controller?.resumePreview();
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int _count = 0;
  bool _isPause = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPause) {
        _count++;
        setState(() {});
      }
    });
  }

  void resumeTimer() {
    _isPause = false;
  }

  void pauseTimer() {
    _isPause = true;
  }

  void stopTimer() {
    _count = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: ThemeData().primaryColor,
        height: 50,
        width: 50,
        child: Center(
            child: Text(
          _getTimeText(),
          style: TextStyle(fontSize: 10, color: Colors.white),
        )),
      ),
    );
  }

  String _getTimeText() {
    if (_count == 0) {
      return '00:00';
    }
    if (_count < 60) {
      return _count < 10 ? '00:0$_count' : '00:$_count';
    }
    return '${_count / 60}:${_count % 60}';
  }
  @override
  void dispose() {
    super.dispose();
    stopTimer();
  }
}
