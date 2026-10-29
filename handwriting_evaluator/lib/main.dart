import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/handwriting_evaluator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize orientation support for both Android Tablets and Apple iPads
  // (preferring landscape on tablets while supporting all four orientations).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HandwritingEvaluatorApp());
}

class HandwritingEvaluatorApp extends StatelessWidget {
  const HandwritingEvaluatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablet Stylus Handwriting Evaluator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HandwritingEvaluatorScreen(),
    );
  }
}
