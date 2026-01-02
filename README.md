# Whisper Flutter New

[![pub package](https://img.shields.io/pub/v/whisper_flutter_new.svg?label=whisper_flutter_new&color=blue)](https://pub.dev/packages/whisper_flutter_new)

# Important Notice:

**I am currently refactoring the functionality and plan to provide flutter bindings for both llama.cpp and whisper.cpp. After the refactoring is complete, I will consider adapting to Windows and MacOS**

Ready to use [whisper.cpp](https://github.com/ggerganov/whisper.cpp) models implementation for iOS
and Android

1. Support AGP8+
2. Support Android 5.0+ & iOS 13+ & MacOS 11+
3. It is optimized and fast

Supported models: tiny、base、small、medium、large-v1、large-v2、large-v3

Quantized models (smaller file size, faster inference): 
- Q5 (recommended balance): tiny-q5_1, base-q5_1, small-q5_1, medium-q5_0, large-v3-q5_0
- Q8 (higher quality): tiny-q8_0, base-q8_0, small-q8_0, medium-q8_0
- Large-v3-turbo: large-v3-turbo (non-quantized), large-v3-turbo-q5_0, large-v3-turbo-q8_0

Recommended Models：base、small、medium (or their quantized versions like base-q5_1)

All models have been actually tested, test devices: Android: Google Pixel 7 Pro, iOS: M1 iOS
simulator，MacOS: M1 MacBookPro & M2 MacMini

## Install library

```bash
flutter pub add whisper_flutter_new
```

## import library

```dart
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
```

## Quickstart

```dart
// Prepare wav file
final Directory documentDirectory = await getApplicationDocumentsDirectory();
final ByteData documentBytes = await rootBundle.load('assets/jfk.wav');

final String jfkPath = '${documentDirectory.path}/jfk.wav';

await File(jfkPath).writeAsBytes(
    documentBytes.buffer.asUint8List(),
);

// Begin whisper transcription
/// China: https://hf-mirror.com/ggerganov/whisper.cpp/resolve/main
/// Other: https://huggingface.co/ggerganov/whisper.cpp/resolve/main
final Whisper whisper = Whisper(
    model: WhisperModel.baseQ5, // Using quantized Q5 model (recommended)
    // or WhisperModel.base for non-quantized version
    downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
);

final String? whisperVersion = await whisper.getVersion();
print(whisperVersion);

final String transcription = await whisper.transcribe(
    transcribeRequest: TranscribeRequest(
        audio: jfkPath,
        isTranslate: true, // Translate result from audio lang to english text
        isNoTimestamps: false, // Get segments in result
        splitOnWord: true, // Split segments on each word 
    ),
);
print(transcription);
```
