import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

///function:
///@author:zhangteng
///@date:2023/7/24
class ScanQRCodeView extends StatefulWidget {
  final bool needChangeCamera; //是否可以切换摄像头
  final Function(InputImage inputImage)? onImage; //图片处理回调
  final Function(List<String> codeList) onCodeList; //结果回调

  const ScanQRCodeView({Key? key, required this.onCodeList, this.needChangeCamera = true, this.onImage})
      : super(key: key);

  @override
  State<ScanQRCodeView> createState() => ScanQRCodeViewState();
}

class ScanQRCodeViewState extends State<ScanQRCodeView> {
  final List<CameraDescription> _cameras = [];
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  CameraController? _controller;
  int _currentCameraIndex = -1; //当前所选的摄像头
  bool _isChangingCameraLens = false;

  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return !_isDataOK()
        ? const Center(child: CircularProgressIndicator())
        : Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Center(
                  child: _isChangingCameraLens
                      ? const Center(child: Text('正在切换摄像头...'))
                      : GestureDetector(
                          onScaleUpdate: (detail) {
                            _zoom(detail);
                          },
                          child: CameraPreview(_controller!)),
                ),
                Positioned(
                    bottom: 50,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [_switchLiveCameraToggle(), _selectFromAlbumIcon(), _switchFlashModeToggle()],
                    ))
              ],
            ),
          );
  }

  ImagePicker? _imagePicker;

  Widget _selectFromAlbumIcon() {
    return SizedBox(
      height: 50.0,
      width: 50.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: _selectPhoto,
        backgroundColor: Colors.black54,
        child: const Icon(
          Icons.photo_library,
          size: 25,
        ),
      ),
    );
  }

  bool _isSelectingPhoto = false;

  void _selectPhoto() async {
    _isSelectingPhoto = true;
    _imagePicker ??= ImagePicker();
    final pickedFile = await _imagePicker!.pickImage(source: ImageSource.gallery);
    _isSelectingPhoto = false;
    if (pickedFile == null) {
      return;
    }
    debugPrint('二维码:pickFile${pickedFile.path}');
    final inputImage = InputImage.fromFilePath(pickedFile.path);
    if (widget.onImage != null) {
      widget.onImage!(inputImage);
    } else {
      _analysisImage(inputImage);
    }
  }

  void _zoom(ScaleUpdateDetails detail) {
    var scale = detail.scale.clamp(_minAvailableZoom, _maxAvailableZoom);
    if (_currentZoomLevel == scale) {
      return;
    }
    _currentZoomLevel = scale;
    _controller?.setZoomLevel(scale);
  }

  Widget _switchLiveCameraToggle() => widget.needChangeCamera
      ? SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: _switchLiveCamera,
            backgroundColor: Colors.black54,
            child: Icon(
              Platform.isIOS ? Icons.flip_camera_ios_outlined : Icons.flip_camera_android_outlined,
              size: 25,
            ),
          ),
        )
      : Container();

  int _currentFlashIndex = 0;
  final flashModeArray = [
    Icons.flash_auto,
    Icons.flash_on,
    Icons.flash_off,
  ];

  Widget _switchFlashModeToggle() => SizedBox(
        width: 50,
        height: 50,
        child: FloatingActionButton(
          heroTag: Object(),
          onPressed: _switchFlashMode,
          backgroundColor: Colors.black54,
          child: Icon(
            _flashModeIcon(),
            size: 25,
          ),
        ),
      );

  ///资源是否准备完成
  bool _isDataOK() {
    if (_cameras.isEmpty || _controller == null) {
      return false;
    }

    return _controller!.value.isInitialized;
  }

  ///初始化摄像头
  void _initCamera() async {
    if (_cameras.isEmpty) {
      final list = await availableCameras();
      _cameras.addAll(list);
    }

    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        //默认选择后置摄像头
        _currentCameraIndex = i;
        break;
      }
    }

    if (_currentCameraIndex != -1) {
      startLiveFeed();
    }
  }

  ///开始接收画面
  Future<void> startLiveFeed() async {
    final camera = _cameras[_currentCameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _initControllerParams();
  }

  bool _isControllerDispose = false;

  ///停止接收画面
  Future<void> stopLiveFeed() async {
    if (_isControllerDispose) {
      return;
    }
    _isControllerDispose = true;
    await _controller?.setFlashMode(FlashMode.off);
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  ///初始化controller
  Future<void> _initControllerParams() async {
    _controller?.initialize().then((value) async {
      if (!mounted) {
        return;
      }
      double minZoomLevel = await _controller!.getMinZoomLevel();
      _currentZoomLevel = minZoomLevel;
      _minAvailableZoom = minZoomLevel;

      double maxZoomLevel = await _controller!.getMaxZoomLevel();
      _maxAvailableZoom = maxZoomLevel;

      _controller?.startImageStream(_processCameraImage);
      _controller?.setFlashMode(FlashMode.auto);
      _isProcessImage = false;

      setState(() {});
    });
  }

  void _processCameraImage(CameraImage image) {
    if (_isSelectingPhoto) {
      //正在从相册选照片就不处理视频流
      return;
    }
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    if (widget.onImage != null) {
      widget.onImage!(inputImage);
    } else {
      _analysisImage(inputImage);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _cameras[_currentCameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  bool _isProcessImage = false;

  ///分析图片
  void _analysisImage(InputImage inputImage) async {
    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (barcodes.isEmpty) {
      return;
    }

    if (_isProcessImage) {
      return;
    }
    _isProcessImage = true;
    List<String> list = barcodes.map((barcode) => barcode.displayValue ?? '').toList();
    widget.onCodeList(list);
    pausePreview();
    // if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
    //
    //   List<String> list = barcodes.map((barcode) => barcode.displayValue ?? '').toList();
    //   widget.onCodeList(list);
    //   stopLiveFeed();
    // } else {
    //   List<String> list = barcodes.map((barcode) => barcode.displayValue ?? '').toList();
    //   widget.onCodeList(list);
    //   stopLiveFeed();
    // }
  }

  void resumePreview(){
    _isProcessImage = false;
    _controller?.resumePreview();
  }

  void pausePreview(){
    _controller?.pausePreview();
  }

  IconData _flashModeIcon() {
    return flashModeArray[_currentFlashIndex];
  }

  Future _switchFlashMode() async {
    _currentFlashIndex++;
    if (_currentFlashIndex == flashModeArray.length) {
      _currentFlashIndex = 0;
    }
    await _controller?.setFlashMode(_getFlashMode());
    setState(() {});
  }

  FlashMode _getFlashMode() {
    if (_currentFlashIndex == 1) {
      return FlashMode.torch;
    } else if (_currentFlashIndex == 2) {
      return FlashMode.off;
    }
    return FlashMode.auto;
  }

  Future _switchLiveCamera() async {
    setState(() => _isChangingCameraLens = true);
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

    await stopLiveFeed();
    await startLiveFeed();
    setState(() => _isChangingCameraLens = false);
  }

  @override
  void dispose() {
    super.dispose();
    stopLiveFeed();
    _barcodeScanner.close();
  }
}
