import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Причина, по которой запись голоса не удалась.
enum VoiceRecordFailure { permissionDenied, startFailed, readFailed }

class VoiceRecordException implements Exception {
  const VoiceRecordException(this.failure, [this.cause]);
  final VoiceRecordFailure failure;
  final Object? cause;

  @override
  String toString() => 'VoiceRecordException: $failure ($cause)';
}

/// Запись голосового сообщения для распознавания речи.
///
/// Пишет моно-речь 16 кГц: AAC в контейнере m4a на мобильных устройствах,
/// Opus/webm в браузере. Не зависит от UI.
class VoiceRecorderService {
  VoiceRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _filePath;

  /// Формат записи, который ожидает `AiService.transcribeAudio`.
  String get format => kIsWeb ? 'webm' : 'm4a';

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const VoiceRecordException(VoiceRecordFailure.permissionDenied);
    }
    try {
      if (kIsWeb) {
        // В браузере путь не нужен: stop() вернёт blob URL.
        await _recorder.start(_config(AudioEncoder.opus), path: '');
        _filePath = null;
      } else {
        final path =
            '${Directory.systemTemp.path}/welmi_voice_'
            '${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(_config(AudioEncoder.aacLc), path: path);
        _filePath = path;
      }
    } catch (e) {
      debugPrint('⚠️ Voice record start error: $e');
      throw VoiceRecordException(VoiceRecordFailure.startFailed, e);
    }
  }

  /// Останавливает запись и возвращает аудио. Временный файл удаляется.
  Future<Uint8List> stopAndRead() async {
    Uint8List? bytes;
    try {
      final stoppedPath = await _recorder.stop();
      if (kIsWeb) {
        if (stoppedPath != null && stoppedPath.isNotEmpty) {
          // На web stop() возвращает blob URL — загружаем байты по нему.
          final res = await http.get(Uri.parse(stoppedPath));
          if (res.statusCode == 200) bytes = res.bodyBytes;
        }
      } else {
        final file = File(stoppedPath ?? _filePath ?? '');
        if (_filePath != null && await file.exists()) {
          bytes = await file.readAsBytes();
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Voice stop error: $e');
      throw VoiceRecordException(VoiceRecordFailure.readFailed, e);
    } finally {
      _filePath = null;
    }
    if (bytes == null || bytes.isEmpty) {
      throw const VoiceRecordException(VoiceRecordFailure.readFailed);
    }
    return bytes;
  }

  /// Прерывает запись без сохранения результата.
  Future<void> cancel() async {
    try {
      await _recorder.cancel();
    } catch (e) {
      debugPrint('⚠️ Voice cancel error: $e');
    }
    final path = _filePath;
    _filePath = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> dispose() => _recorder.dispose();

  RecordConfig _config(AudioEncoder encoder) => RecordConfig(
    encoder: encoder,
    bitRate: 64000,
    sampleRate: 16000, // оптимум для распознавания речи
    numChannels: 1, // моно достаточно для голоса
  );
}
