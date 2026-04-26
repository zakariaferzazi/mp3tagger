import 'dart:async';
import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mp3tageditor/core/services/purchase_service.dart';
import 'package:mp3tageditor/core/services/shared_prefs_service.dart';

final audioEditorServiceProvider = Provider<AudioEditorService>((ref) {
  return AudioEditorService(ref);
});

class AudioFileState {
  final File file;
  final AudioTag? tag;

  AudioFileState({required this.file, this.tag});
}

class AudioTag {
  final String? title;
  final String? trackArtist;
  final String? albumArtist;
  final String? album;
  final String? genre;
  final DateTime? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final Duration? duration;
  final int? bitrate;
  final int? sampleRate;
  final List<Picture> pictures;
  final List<String> genres;

  const AudioTag({
    this.title,
    this.trackArtist,
    this.albumArtist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.pictures = const [],
    this.genres = const [],
  });

  factory AudioTag.fromMetadata(AudioMetadata metadata) {
    return AudioTag(
      title: metadata.title,
      trackArtist: metadata.artist,
      albumArtist:
          metadata.performers.isNotEmpty ? metadata.performers.first : metadata.artist,
      album: metadata.album,
      genre: metadata.genres.isNotEmpty ? metadata.genres.first : null,
      year: metadata.year,
      trackNumber: metadata.trackNumber,
      trackTotal: metadata.trackTotal,
      discNumber: metadata.discNumber,
      discTotal: metadata.totalDisc,
      duration: metadata.duration,
      bitrate: metadata.bitrate,
      sampleRate: metadata.sampleRate,
      pictures: List<Picture>.unmodifiable(metadata.pictures),
      genres: List<String>.unmodifiable(metadata.genres),
    );
  }
}

class AudioEditorService {
  final Ref ref;
  String? _lastWriteError;
  Future<void> _tagOperationQueue = Future.value();

  AudioEditorService(this.ref);

  String? get lastWriteError => _lastWriteError;

  bool _supportsWrite(String filePath) {
    final path = filePath.toLowerCase();
    return path.endsWith('.mp3') ||
        path.endsWith('.m4a') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.flac') ||
        path.endsWith('.wav');
  }

  Future<T> _runTagOperation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    _tagOperationQueue = _tagOperationQueue.then((_) async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<void> consumeFreeUse() async {
    final hasPremium = await purchaseService.hasPremium();
    if (hasPremium) return;

    final prefs = ref.read(sharedPrefsServiceProvider);
    final edits = prefs.getInt('free_edits_done') ?? 0;
    await prefs.setInt('free_edits_done', edits + 1);
  }

  Future<AudioTag?> readTags(String filePath) async {
    try {
      final metadata = await _runTagOperation(
        () async => readMetadata(File(filePath), getImage: true),
      );
      return AudioTag.fromMetadata(metadata);
    } catch (e) {
      print('Error reading tags: $e');
    }
    return null;
  }

  Future<bool> writeTags(String filePath, AudioTag newTag) async {
    _lastWriteError = null;
    try {
      if (!_supportsWrite(filePath)) {
        _lastWriteError =
            'This file type is read-only with audio_metadata_reader. Supported write formats are MP3, MP4/M4A/MOV, FLAC, and WAV.';
        return false;
      }

      await _runTagOperation(() async {
        updateMetadata(File(filePath), (metadata) {
          metadata.setTitle(newTag.title);
          metadata.setArtist(newTag.trackArtist);
          metadata.setAlbum(newTag.album);
          metadata.setYear(newTag.year);
          metadata.setTrackNumber(newTag.trackNumber);
          metadata.setTrackTotal(newTag.trackTotal);
          metadata.setCD(newTag.discNumber, newTag.discTotal);
          metadata.setGenres(
            newTag.genre == null || newTag.genre!.trim().isEmpty
                ? const <String>[]
                : <String>[newTag.genre!.trim()],
          );
          metadata.setPictures(newTag.pictures);
        });
      });

      await consumeFreeUse();

      return true;
    } catch (e) {
      _lastWriteError = e.toString();
      print('Error writing tags: $e');

      if (Platform.isIOS &&
          _lastWriteError != null &&
          _lastWriteError!.contains('FlutterRustBridgeBase') &&
          _lastWriteError!.contains('singletons')) {
        _lastWriteError =
            'Audio engine initialized more than once on iOS runtime. Close the app fully and reopen, then try again.';
      }

      return false;
    }
  }

  PurchaseService get purchaseService => ref.read(purchaseServiceProvider);

  Future<int> getRemainingFreeEdits() async {
    final hasPremium = await purchaseService.hasPremium();
    if (hasPremium) return -1;

    final prefs = ref.read(sharedPrefsServiceProvider);
    final editsDone = prefs.getInt('free_edits_done') ?? 0;
    final remaining = 1 - editsDone;
    return remaining > 0 ? remaining : 0;
  }
}
