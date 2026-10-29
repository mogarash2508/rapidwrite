# Stylus Handwriting Analysis & Aesthetic Evaluation Module (Flutter Tablet App)

Cross-platform Flutter application engineered for **Android Tablets** and **Apple iPads** (including 120Hz ProMotion Apple Pencil & active Android stylus support).

## Project Structure

```text
handwriting_evaluator/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── android/
│   ├── build.gradle
│   ├── settings.gradle
│   ├── gradle.properties
│   └── app/
│       ├── build.gradle                  # minSdkVersion 24, compileSdkVersion 34, ML Kit rules
│       └── src/main/
│           ├── AndroidManifest.xml       # Internet, storage, & stylus hardware declarations
│           └── kotlin/com/example/handwriting_evaluator/MainActivity.kt
├── ios/
│   └── Runner/
│       └── Info.plist                    # Photo library permissions, Apple Pencil & iPad flags
├── lib/
│   ├── main.dart                         # Tablet orientation setup & Material 3 entry point
│   ├── models/
│   │   ├── sentence_prompt.dart          # Sentence prompts with fixed difficulty-based timers
│   │   ├── stroke_model.dart             # High-precision StylusPoint & StylusStroke models
│   │   └── evaluation_result.dart        # Speed metrics, Aesthetic scores, & Result models
│   ├── services/
│   │   ├── speed_calculator_service.dart # Accuracy-independent physical writing speed engine
│   │   ├── ink_recognition_service.dart  # Google ML Kit Digital Ink Recognition service
│   │   └── aesthetic_evaluation_service.dart # Vision AI + on-device geometric neatness evaluator
│   ├── widgets/
│   │   ├── sentence_prompt_banner.dart   # Top prompt container with auto-disappearing timer
│   │   ├── stylus_canvas.dart            # Center canvas with strict palm rejection & screenshot capture
│   │   └── results_dashboard.dart        # Bottom results panel (hidden until submission)
│   └── screens/
│       └── handwriting_evaluator_screen.dart # Full tablet screen coordinating timers & analysis
└── test/
    └── widget_test.dart                  # Unit & widget tests for speed kinematics and UI
```

## Quick Start

1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Optional: Provide a Vision API key (`--dart-define=VISION_API_KEY=your_key`) to enable remote multimodal LLM vision grading alongside the built-in offline geometric/visual analyzer:
   ```bash
   flutter run --dart-define=VISION_API_KEY=AIzaSy...
   ```
