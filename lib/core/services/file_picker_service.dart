import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle file picker operations
class FilePickerService {
  static const List<String> _audioExtensions = <String>[
    'mp3',
    'm4a',
    'mp4',
    'mov',
    'wav',
    'flac',
    'ogg',
    'opus',
  ];

  /// Pick audio files
  /// Returns null if user cancels or an error occurs
  Future<List<File>?> pickAudioFiles({bool allowMultiple = true}) async {
    try {
      print('Opening file picker...');
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        allowMultiple: allowMultiple,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('File picker timeout: picker did not return in time');
          return null;
        },
      );

      if (result == null) {
        print('File picker cancelled by user');
        return null;
      }

      if (result.paths.isEmpty) {
        print('No files selected');
        return null;
      }

      final files =
          result.paths.whereType<String>().map((p) => File(p)).toList();
      print('Successfully picked ${files.length} files');
      return files;
    } catch (e, stackTrace) {
      print('File picker error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Save a file
  /// Returns the file path if successful, null if cancelled or an error occurs
  Future<String?> saveFile({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      print('Opening file save dialog...');
      final String? outputFile = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
      );

      if (outputFile != null) {
        print('File saved to: $outputFile');
      } else {
        print('File save cancelled');
      }
      return outputFile;
    } catch (e, stackTrace) {
      print('File save error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

final filePickerServiceProvider = Provider((ref) => FilePickerService());
