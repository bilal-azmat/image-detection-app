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
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.isNotEmpty) {
        setState(() {
          selectedCameraIdx = 0;
        });
        _initCameraController(cameras![selectedCameraIdx]);
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
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
    selectedCameraIdx = selectedCameraIdx == 0 ? 1 : 0;
    _initCameraController(cameras![selectedCameraIdx]);
  }

  Future<void> _takePicture() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';

      await controller!.takePicture().then((XFile? file) {
        if (file != null) {
          setState(() {
            imagePath = file.path;
          });
          _uploadImage(File(imagePath!));
        }
      });
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _uploadImage(File image) async {
    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse('http://192.168.1.102:5001/predict');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

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
      appBar: AppBar(
        title: Text('Camera'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                CameraPreview(controller!),
                if (imagePath != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.white.withOpacity(0.8),
                      child: Text(
                        'Prediction: ${predictionResult ?? "Not Found!"}',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: 'switch',
                  child: Icon(Icons.switch_camera),
                  onPressed: _onSwitchCamera,
                ),
                FloatingActionButton(
                  heroTag: 'capture',
                  child: Icon(Icons.camera),
                  onPressed: isLoading ? null : _takePicture,
                ),
              ],
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
