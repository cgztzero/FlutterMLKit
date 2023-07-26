import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

///function:
///@author:zhangteng
///@date:2023/7/24
class RecordVideoResultPage extends StatefulWidget {
  final String path;

  const RecordVideoResultPage({Key? key, required this.path}) : super(key: key);

  @override
  State<RecordVideoResultPage> createState() => _RecordVideoResultPageState();
}

class _RecordVideoResultPageState extends State<RecordVideoResultPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('video result'),
        ),
        body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
