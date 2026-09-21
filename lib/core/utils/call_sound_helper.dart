import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Helper utility that generates clean, standard PCM WAV audio files
/// (telephone ringback tone and alert beeps) for Agora and VoIP playback.
class CallSoundHelper {
  static String? _cachedRingtonePath;
  static String? _cachedBeepPath;

  /// Returns the absolute local file path to the standard telephone ringback tone WAV file.
  /// If the file does not already exist, it is generated and cached on the device filesystem.
  static Future<String?> getRingtonePath() async {
    try {
      if (_cachedRingtonePath != null && File(_cachedRingtonePath!).existsSync()) {
        return _cachedRingtonePath;
      }

      final tempDir = Directory.systemTemp;
      final ringtoneFile = File('${tempDir.path}/call_ringback_tone.wav');

      if (!ringtoneFile.existsSync() || ringtoneFile.lengthSync() < 1000) {
        final wavBytes = _generateRingbackToneWav();
        await ringtoneFile.writeAsBytes(wavBytes, flush: true);
        debugPrint('🔔 [CallSoundHelper] Generated ringback tone at: ${ringtoneFile.path} (${wavBytes.length} bytes)');
      }

      _cachedRingtonePath = ringtoneFile.path;
      return _cachedRingtonePath;
    } catch (e) {
      debugPrint('⚠️ [CallSoundHelper] Failed to create ringtone file: $e');
      return null;
    }
  }

  /// Returns the absolute local file path to a short alert beep tone WAV file.
  static Future<String?> getBeepSoundPath() async {
    try {
      if (_cachedBeepPath != null && File(_cachedBeepPath!).existsSync()) {
        return _cachedBeepPath;
      }

      final tempDir = Directory.systemTemp;
      final beepFile = File('${tempDir.path}/call_beep_tone.wav');

      if (!beepFile.existsSync() || beepFile.lengthSync() < 500) {
        final wavBytes = _generateBeepToneWav();
        await beepFile.writeAsBytes(wavBytes, flush: true);
      }

      _cachedBeepPath = beepFile.path;
      return _cachedBeepPath;
    } catch (e) {
      debugPrint('⚠️ [CallSoundHelper] Failed to create beep file: $e');
      return null;
    }
  }

  /// Generates standard dual-frequency telephone ringback tone:
  /// 440 Hz + 480 Hz, 1.5s ring tone + 2.0s silence = 3.5s cycle at 16,000 Hz 16-bit Mono PCM.
  static Uint8List _generateRingbackToneWav() {
    const int sampleRate = 16000;
    const double toneDuration = 1.5; // seconds of ring sound
    const double silenceDuration = 2.0; // seconds of pause
    const int numChannels = 1;
    const int bitsPerSample = 16;

    final int toneSamples = (sampleRate * toneDuration).toInt();
    final int silenceSamples = (sampleRate * silenceDuration).toInt();
    final int totalSamples = toneSamples + silenceSamples;
    final int dataByteLength = totalSamples * numChannels * (bitsPerSample ~/ 8);

    final wavHeader = _buildWavHeader(
      dataLength: dataByteLength,
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
    );

    final byteData = ByteData(dataByteLength);
    int byteOffset = 0;

    const double freq1 = 440.0;
    const double freq2 = 480.0;
    const int fadeSamples = 400; // 25ms fade in/out for smooth audio

    // 1. Synthesize Tone Portion
    for (int i = 0; i < toneSamples; i++) {
      final double t = i / sampleRate;
      final double rawSignal = 0.5 * sin(2 * pi * freq1 * t) + 0.5 * sin(2 * pi * freq2 * t);

      // Envelope shaping (fade in and fade out)
      double envelope = 1.0;
      if (i < fadeSamples) {
        envelope = i / fadeSamples;
      } else if (i > toneSamples - fadeSamples) {
        envelope = (toneSamples - i) / fadeSamples;
      }

      final int sampleValue = (rawSignal * envelope * 0.75 * 32767).round().clamp(-32768, 32767);
      byteData.setInt16(byteOffset, sampleValue, Endian.little);
      byteOffset += 2;
    }

    // 2. Synthesize Silence Portion
    for (int i = 0; i < silenceSamples; i++) {
      byteData.setInt16(byteOffset, 0, Endian.little);
      byteOffset += 2;
    }

    final fullBytes = Uint8List(wavHeader.length + dataByteLength);
    fullBytes.setAll(0, wavHeader);
    fullBytes.setAll(wavHeader.length, byteData.buffer.asUint8List());

    return fullBytes;
  }

  /// Generates a single alert beep tone (880 Hz, 0.25s)
  static Uint8List _generateBeepToneWav() {
    const int sampleRate = 16000;
    const double duration = 0.25;
    const int numChannels = 1;
    const int bitsPerSample = 16;

    final int totalSamples = (sampleRate * duration).toInt();
    final int dataByteLength = totalSamples * numChannels * (bitsPerSample ~/ 8);

    final wavHeader = _buildWavHeader(
      dataLength: dataByteLength,
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
    );

    final byteData = ByteData(dataByteLength);
    int byteOffset = 0;
    const double freq = 880.0;

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double rawSignal = sin(2 * pi * freq * t);
      final int sampleValue = (rawSignal * 0.7 * 32767).round().clamp(-32768, 32767);
      byteData.setInt16(byteOffset, sampleValue, Endian.little);
      byteOffset += 2;
    }

    final fullBytes = Uint8List(wavHeader.length + dataByteLength);
    fullBytes.setAll(0, wavHeader);
    fullBytes.setAll(wavHeader.length, byteData.buffer.asUint8List());

    return fullBytes;
  }

  /// Builds standard 44-byte RIFF WAV Header
  static Uint8List _buildWavHeader({
    required int dataLength,
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
  }) {
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int totalLength = 36 + dataLength;
    final ByteData buffer = ByteData(44);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, totalLength, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size = 16 for PCM
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat = 1 (PCM)
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // "data" sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataLength, Endian.little);

    return buffer.buffer.asUint8List();
  }
}
