import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // 이미지 처리용
import 'package:flutter/services.dart' show rootBundle;

class AiCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AiCameraScreen({super.key, required this.cameras});

  @override
  State<AiCameraScreen> createState() => _AiCameraScreenState();
}

class _AiCameraScreenState extends State<AiCameraScreen> {
  CameraController? _controller;
  Interpreter? _interpreter;
  List<String>? _labels;
  String _result = "촬영 버튼을 눌러보세요!";
  bool _isBusy = false; // 분석 중인지 확인

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  // 1. 카메라 초기화
  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  // 2. TFLite 모델 및 라벨 로드
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      print("✅ 모델 로드 성공");

      // 라벨 파일 읽기
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      print("✅ 라벨 로드 성공: $_labels");
    } catch (e) {
      print("⚠️ 모델 로드 실패: $e");
    }
  }

  // 3. 사진 찍고 분석하기
  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;

    setState(() {
      _isBusy = true;
      _result = "분석 중...";
    });

    try {
      // 사진 촬영
      final imageFile = await _controller!.takePicture();

      // 이미지 전처리 (파일 읽기 -> 리사이징 -> 데이터 변환)
      var imageBytes = await File(imageFile.path).readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        // Teachable Machine은 224x224 크기를 원합니다.
        img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

        // 입력 데이터 만들기 (Float32List [1, 224, 224, 3])
        var input = _imageToFloat32List(resizedImage);

        // 출력 데이터 그릇 만들기 (클래스 개수만큼)
        var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

        // 추론 실행!
        _interpreter?.run(input, output);

        // 결과 해석 (가장 높은 확률 찾기)
        List<double> probabilities = List<double>.from(output[0]);
        int maxIndex = 0;
        double maxProb = 0.0;

        for (int i = 0; i < probabilities.length; i++) {
          if (probabilities[i] > maxProb) {
            maxProb = probabilities[i];
            maxIndex = i;
          }
        }

        setState(() {
          String predictedLabel = _labels![maxIndex];
          // 라벨에서 앞의 숫자 제거 (예: "0 Plastic" -> "Plastic")
          predictedLabel = predictedLabel.replaceAll(RegExp(r'^[0-9]+\s'), '');
          _result = "결과: $predictedLabel\n확률: ${(maxProb * 100).toStringAsFixed(1)}%";
        });
      }
    } catch (e) {
      print("에러 발생: $e");
      setState(() {
        _result = "에러가 발생했습니다.";
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  // 이미지를 모델이 이해하는 숫자 배열(Float32)로 변환하는 함수
  List<dynamic> _imageToFloat32List(img.Image image) {
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 224; i++) {
      for (var j = 0; j < 224; j++) {
        var pixel = image.getPixel(j, i);
        // RGB 값을 0~1 사이 소수로 정규화 (Teachable Machine 기본 설정)
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.reshape([1, 224, 224, 3]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("AI 쓰레기 분류기")),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!), // 카메라 화면
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  _result,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _captureAndAnalyze,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("촬영 및 분석", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}