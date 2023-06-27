import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ibandetector/views/text_recognizer/text_recognizer.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Iban detection app',
      debugShowCheckedModeBanner: false,
      home: TextRecognizerView(),
    );
  }
}
