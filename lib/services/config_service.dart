// services/config_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ConfigService {
static const String configDir = 'configurations'; // C:\Users\aethe\Documents\configurations
  
  static Future<String> get _configPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final configDirPath = path.join(appDir.path, configDir);
    
    // Create the config directory if it doesn't exist
    final dir = Directory(configDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return configDirPath;
  }

  static Future<List<String>> getAvailableConfigs() async {
    final configDirPath = await _configPath;
    final dir = Directory(configDirPath);
    
    final List<String> configs = [];
    await for (final entity in dir.list()) {
      if (entity is File && path.extension(entity.path) == '.json') {
        configs.add(path.basenameWithoutExtension(entity.path));
      }
    }
    
    return configs;
  }

  static Future<List<Map<String, dynamic>>> loadConfig(String name) async {
    try {
      final configDirPath = await _configPath;
      final file = File(path.join(configDirPath, '$name.json'));
      
      if (!await file.exists()) {
        throw Exception('Configuration $name does not exist');
      }
      
      final String contents = await file.readAsString();
      final List<dynamic> json = jsonDecode(contents);
      return json.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading configuration: $e');
      rethrow;
    }
  }

  static Future<void> saveConfig(String name, List<Map<String, dynamic>> config) async {
    try {
      final configDirPath = await _configPath;
      final file = File(path.join(configDirPath, '$name.json'));
      
      final String json = jsonEncode(config);
      await file.writeAsString(json);
    } catch (e) {
      print('Error saving configuration: $e');
      rethrow;
    }
  }

  static Future<void> deleteConfig(String name) async {
    try {
      final configDirPath = await _configPath;
      final file = File(path.join(configDirPath, '$name.json'));
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting configuration: $e');
      rethrow;
    }
  }

  // Initialize with default configurations if none exist
  // Initialize with default configurations if none exist
  static Future<void> initializeDefaultConfigs() async {
    final configDirPath = await _configPath;
    final configs = await getAvailableConfigs();
    
    if (configs.isEmpty) {
      // Load and save default configurations from assets. THESE ARE NOT SAVED IN THE CONFIG PATH! YOU CAN'T EDIT THEM THROUGH THE APP!
      try {
        // Load forJake config
        final String forJakeJson = await rootBundle.loadString('assets/configs/forJake.json');
        await File(path.join(configDirPath, 'forJake.json'))
          .writeAsString(forJakeJson);

        // Load masterpiece config
        final String masterpieceJson = await rootBundle.loadString('assets/configs/masterpiece.json');
        await File(path.join(configDirPath, 'masterpiece.json'))
          .writeAsString(masterpieceJson);
      } catch (e) {
        print('Error loading default configurations: $e');
        rethrow;
      }
    }
  }
}