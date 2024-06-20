import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription>? cameras;
  CameraController? controller;
  int selectedCameraIdx = 0;
  String? imagePath;
  bool isLoading = false;
  String? predictionResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        setState(() {
          selectedCameraIdx = 0;
        });
        _initCameraController(cameras![selectedCameraIdx]);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller!.addListener(() {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        print('Camera error ${controller!.value.errorDescription}');
      }
    });

    try {
      await controller!.initialize();
      setState(() {}); // Update state to trigger camera preview
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _onSwitchCamera() {
    if (cameras != null && cameras!.length > 1) {
      selectedCameraIdx = selectedCameraIdx == 0 ? 1 : 0;
      _initCameraController(cameras![selectedCameraIdx]);
    }
  }

  Future<void> _captureAndUploadImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';

      await controller!.takePicture().then((XFile? file) async {
        if (file != null) {
          setState(() {
            imagePath = file.path;
          });

          // Upload the image
          final uri = Uri.parse('http://192.168.1.101:5001/predict');
          var request = http.MultipartRequest('POST', uri);
          request.files.add(await http.MultipartFile.fromPath('file', imagePath!));

          try {
            var response = await request.send();
            if (response.statusCode == 200) {
              var jsonResponse = await response.stream.bytesToString();
              var predictions = jsonDecode(jsonResponse)['predictions'] as List;
              var prediction = predictions.isNotEmpty ? predictions[0] : null;

              setState(() {
                predictionResult = prediction;
              });

              print('Prediction: $prediction');
            } else {
              print('Failed to upload image');
            }
          } catch (e) {
            print('Upload error: $e');
          }
        }
      });
    } catch (e) {
      print('Error capturing image: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Container(
                height: MediaQuery.of(context).size.height,
                child: CameraPreview(controller!)),
            if (imagePath != null)
              Positioned(
                bottom: 100,
                left: 10,
                child: Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.white.withOpacity(0.8),
                  child: Text(
                    'Prediction: ${predictionResult ?? ""}',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.switch_camera, color: Colors.white),
                      onPressed: _onSwitchCamera,
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: isLoading ? null : _captureAndUploadImage,
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
