import 'dart:ui';

import 'package:flutter/material.dart';

///function:
///@author:zhangteng
///@date:2023/7/22
class DrawBoardPage extends StatefulWidget {
  const DrawBoardPage({Key? key}) : super(key: key);

  @override
  State<DrawBoardPage> createState() => _DrawBoardPageState();
}

class _DrawBoardPageState extends State<DrawBoardPage> {
  Color _selectColor = Colors.black;
  final List<List<_DrawingPoint>> points = [];
  double _strokeWidth = 5;

  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.pink,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('draw board'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (detail) {
              setState(() {
                points.add([
                  _DrawingPoint(
                      detail.localPosition,
                      Paint()
                        ..color = _selectColor
                        ..isAntiAlias = true
                        ..strokeWidth = _strokeWidth
                        ..strokeCap = StrokeCap.round)
                ]);
              });
            },
            onPanUpdate: (detail) {
              setState(() {
                points.last.add(_DrawingPoint(
                    detail.localPosition,
                    Paint()
                      ..color = _selectColor
                      ..isAntiAlias = true
                      ..strokeWidth = _strokeWidth
                      ..strokeCap = StrokeCap.round));
              });
            },
            onPanEnd: (DragEndDetails detail) {
              debugPrint('onPanEnd');
            },
            child: CustomPaint(
              painter: _DrawingPainter(points),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 50,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 10,
            child: Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        points.clear();
                      });
                    },
                    child: Text('clear')),
                const Padding(padding: EdgeInsets.only(left: 5)),
                ElevatedButton(
                    onPressed: () {
                      if (points.isEmpty) {
                        return;
                      }
                      setState(() {
                        points.removeLast();
                      });
                    },
                    child: Text('back')),
                Slider(
                    value: _strokeWidth,
                    max: 10,
                    min: 1,
                    onChanged: (val) {
                      setState(() {
                        _strokeWidth = val;
                      });
                    }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: Colors.grey[200],
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(colors.length, (index) => _buildColorChose(colors[index])),
          ),
        ),
      ),
    );
  }

  Widget _buildColorChose(Color color) {
    bool isSelect = _selectColor == color;

    return GestureDetector(
      onTap: () {
        if (isSelect) {
          return;
        }
        setState(() {
          _selectColor = color;
        });
      },
      child: Container(
        height: isSelect ? 50 : 40,
        width: isSelect ? 50 : 40,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle, border: isSelect ? Border.all(color: Colors.white, width: 3) : null),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  List<List<_DrawingPoint>> points;

  _DrawingPainter(this.points);

  List<Offset> offsetList = [];

  @override
  void paint(Canvas canvas, Size size) {
    int length = points.length;
    int childLength = 0;
    for (int i = 0; i < length; i++) {
      List<_DrawingPoint> list = points[i];
      childLength = list.length;
      for (int j = 0; j < childLength; j++) {
        if (j == childLength - 1) {
          canvas.drawPoints(PointMode.points, [list[j].offset], list[j].paint);
          continue;
        }
        canvas.drawLine(list[j].offset, list[j + 1].offset, list[j].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _DrawingPoint {
  Offset offset;
  Paint paint;

  _DrawingPoint(this.offset, this.paint);
}
