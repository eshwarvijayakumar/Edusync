import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_material.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _materialsStorageKey = 'edusync_saved_materials_v1';

  /// Lets the student pick a PDF or TXT document with size & format validation
  Future<StudyMaterial?> pickAndUploadDocument(String userId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx', 'md'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      // Validate size (< 15MB)
      if (file.size > AppConstants.maxUploadSizeBytes) {
        throw Exception(
          'File exceeds maximum permitted size of 15 MB. Please choose a smaller document.',
        );
      }

      final extension = (file.extension ?? 'pdf').toLowerCase();
      String extractedText = '';

      // If text-based file, read content
      if (extension == 'txt' || extension == 'md') {
        if (file.bytes != null) {
          extractedText = utf8.decode(file.bytes!, allowMalformed: true);
        } else if (file.path != null) {
          final f = File(file.path!);
          extractedText = await f.readAsString();
        }
      } else {
        // Mock / placeholder text extracted for PDF in client
        extractedText = 'Extracted summary and key definitions from ${file.name}. Includes unit concepts, formulas, and diagrams.';
      }

      final material = StudyMaterial(
        id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: file.name.replaceAll('.$extension', ''),
        fileName: file.name,
        fileType: extension,
        fileSizeBytes: file.size,
        extractedText: extractedText,
      );

      // Save locally
      await _saveMaterialLocally(material);

      // Save to Supabase storage / DB if connected
      if (SupabaseService().isConfigured) {
        try {
          await SupabaseService().client.from('study_materials').insert(material.toJson());
        } catch (e) {
          debugPrint('Remote material sync note: $e');
        }
      }

      return material;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveMaterialLocally(StudyMaterial material) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_materialsStorageKey);
    List<dynamic> list = [];
    if (jsonStr != null) {
      list = jsonDecode(jsonStr);
    }
    list.insert(0, material.toJson());
    await prefs.setString(_materialsStorageKey, jsonEncode(list));
  }

  Future<List<StudyMaterial>> loadMaterials(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_materialsStorageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list
            .map((item) => StudyMaterial.fromJson(item as Map<String, dynamic>))
            .where((m) => m.userId == userId || userId.isEmpty)
            .toList();
      } catch (e) {
        debugPrint('Error loading saved study materials: $e');
      }
    }
    return [];
  }

  Future<void> deleteMaterial(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_materialsStorageKey);
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      list.removeWhere((item) => item['id'] == materialId);
      await prefs.setString(_materialsStorageKey, jsonEncode(list));
    }
  }
}
