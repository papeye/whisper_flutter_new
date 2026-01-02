/*
 * Copyright (c) 田梓萱[小草林] 2021-2024.
 * All Rights Reserved.
 * All codes are protected by China's regulations on the protection of computer software, and infringement must be investigated.
 * 版权所有 (c) 田梓萱[小草林] 2021-2024.
 * 所有代码均受中国《计算机软件保护条例》保护，侵权必究.
 */

import "dart:io";

import "package:flutter/foundation.dart";

/// Available whisper models
enum WhisperModel {
  // no model
  none(""),

  /// tiny model for all languages
  tiny("tiny"),

  /// base model for all languages
  base("base"),

  /// small model for all languages
  small("small"),

  /// medium model for all languages
  medium("medium"),

  /// large model for all languages
  largeV1("large-v1"),
  largeV2("large-v2"),
  largeV3("large-v3"),

  // Quantized models - Q5 (recommended balance of quality and size)
  /// tiny model quantized to Q5_1
  tinyQ5("tiny-q5_1"),

  /// base model quantized to Q5_1
  baseQ5("base-q5_1"),

  /// small model quantized to Q5_1
  smallQ5("small-q5_1"),

  /// medium model quantized to Q5_0
  mediumQ5("medium-q5_0"),

  /// large-v3 model quantized to Q5_0
  largeV3Q5("large-v3-q5_0"),

  // Quantized models - Q8 (higher quality)
  /// tiny model quantized to Q8_0
  tinyQ8("tiny-q8_0"),

  /// base model quantized to Q8_0
  baseQ8("base-q8_0"),

  /// small model quantized to Q8_0
  smallQ8("small-q8_0"),

  /// medium model quantized to Q8_0
  mediumQ8("medium-q8_0"),

  /// large-v3-turbo model (non-quantized)
  largeV3Turbo("large-v3-turbo"),

  /// large-v3-turbo model quantized to Q5_0
  largeV3TurboQ5("large-v3-turbo-q5_0"),

  /// large-v3-turbo model quantized to Q8_0
  largeV3TurboQ8("large-v3-turbo-q8_0");

  const WhisperModel(this.modelName);

  /// Public name of model
  final String modelName;

  /// Get local path of model file
  String getPath(String dir) {
    return "$dir/ggml-$modelName.bin";
  }
}

/// Callback function for download progress updates
/// [bytesDownloaded] - number of bytes downloaded so far
/// [totalBytes] - total number of bytes to download (null if unknown)
/// [percentage] - download percentage (null if totalBytes is unknown)
typedef DownloadProgressCallback = void Function(
  int bytesDownloaded,
  int? totalBytes,
  double? percentage,
);

/// Download [model] to [destinationPath]
/// [onProgress] is an optional callback that reports download progress
Future<String> downloadModel({
  required WhisperModel model,
  required String destinationPath,
  String? downloadHost,
  DownloadProgressCallback? onProgress,
}) async {
  if (kDebugMode) {
    debugPrint("Download model ${model.modelName}");
  }
  final httpClient = HttpClient();

  Uri modelUri;

  if (downloadHost == null || downloadHost.isEmpty) {
    /// Huggingface url to download model
    modelUri = Uri.parse(
      "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${model.modelName}.bin",
    );
  } else {
    modelUri = Uri.parse(
      "$downloadHost/ggml-${model.modelName}.bin",
    );
  }

  try {
    final request = await httpClient.getUrl(modelUri);
    final response = await request.close();

    // Check if the response is successful
    if (response.statusCode != 200) {
      await response.drain();
      throw Exception(
        "Failed to download model ${model.modelName}: HTTP ${response.statusCode}. "
        "The model file may not exist at ${modelUri.toString()}",
      );
    }

    // Get content length from headers if available
    final contentLengthHeader = response.headers.value("content-length");
    final int? totalBytes =
        contentLengthHeader != null ? int.tryParse(contentLengthHeader) : null;

    final file = File("$destinationPath/ggml-${model.modelName}.bin");
    final raf = file.openSync(mode: FileMode.write);

    try {
      int bytesDownloaded = 0;
      int lastReportedBytes = 0;
      const int reportInterval = 1024 * 1024; // Report every 1MB

      await for (var chunk in response) {
        raf.writeFromSync(chunk);
        bytesDownloaded += chunk.length;

        // Report progress if callback is provided
        if (onProgress != null) {
          final double? percentage = totalBytes != null
              ? (bytesDownloaded / totalBytes * 100).clamp(0.0, 100.0)
              : null;
          onProgress(bytesDownloaded, totalBytes, percentage);
        }

        // Print progress to console in debug mode (every 1MB or on completion)
        if (kDebugMode) {
          if (bytesDownloaded - lastReportedBytes >= reportInterval ||
              bytesDownloaded == totalBytes) {
            if (totalBytes != null) {
              final double percentage =
                  (bytesDownloaded / totalBytes * 100).clamp(0.0, 100.0);
              final String downloadedMB =
                  (bytesDownloaded / (1024 * 1024)).toStringAsFixed(2);
              final String totalMB =
                  (totalBytes / (1024 * 1024)).toStringAsFixed(2);
              debugPrint(
                "Download progress: $downloadedMB MB / $totalMB MB (${percentage.toStringAsFixed(1)}%)",
              );
            } else {
              final String downloadedMB =
                  (bytesDownloaded / (1024 * 1024)).toStringAsFixed(2);
              debugPrint("Download progress: $downloadedMB MB");
            }
            lastReportedBytes = bytesDownloaded;
          }
        }
      }
      await raf.close();

      if (kDebugMode) {
        debugPrint("Download complete. Path = ${file.path}");
      }
      return file.path;
    } catch (e) {
      await raf.close();
      // Try to delete the incomplete file
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      rethrow;
    }
  } on SocketException catch (e) {
    throw Exception(
      "Network error while downloading model ${model.modelName}: ${e.message}",
    );
  } on HttpException catch (e) {
    throw Exception(
      "HTTP error while downloading model ${model.modelName}: ${e.message}",
    );
  } catch (e) {
    throw Exception(
      "Failed to download model ${model.modelName} from ${modelUri.toString()}: $e",
    );
  } finally {
    httpClient.close();
  }
}
