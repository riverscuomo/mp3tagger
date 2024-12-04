// services/config_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ConfigService {
static const String configDir = 'MP3 Tagger'; // C:\Users\aethe\Documents\MP3 Tagger
  
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

  // Add default configs from assets
  configs.addAll(['default']); // Add your asset configs here

  // Get configs from config directory
  await for (final entity in dir.list()) {
    if (entity is File && path.extension(entity.path) == '.json') {
      final configName = path.basenameWithoutExtension(entity.path);
      if (!configs.contains(configName)) {
        configs.add(configName);
      }
    }
  }

  return configs;
}

static Future<void> ensureConfigDirectoryExists() async {
  final configDirPath = await _configPath;
  final dir = Directory(configDirPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}



static Future<Map<String, dynamic>> loadConfig(String name) async {
  try {
    final configDirPath = await _configPath;
    final file = File(path.join(configDirPath, '$name.json'));

    if (await file.exists()) {
      final String contents = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(contents);
      return json;
    } else {
      // Try to load from assets
      return await loadConfigFromAssets(name);
    }
  } catch (e) {
    print('Error loading configuration: $e');
    rethrow;
  }
}



static Future<Map<String, dynamic>> loadConfigFromAssets(
    String name) async {
  try {
    final String contents =
        await rootBundle.loadString('assets/configs/$name.json');
    final Map<String, dynamic> json = jsonDecode(contents);
    return json;
  } catch (e) {
    print('Error loading configuration from assets: $e');
    rethrow;
  }
}


static Future<void> saveConfig(String name, Map<String, dynamic> config) async {
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
        final String defaultJson = await rootBundle.loadString('assets/configs/default.json');
        await File(path.join(configDirPath, 'default.json'))
          .writeAsString(defaultJson);

       
      } catch (e) {
        print('Error loading default configurations: $e');
        rethrow;
      }
    }
  }

static Future<String?> getLastModifiedConfigName() async {
  final configDirPath = await _configPath;
  final dir = Directory(configDirPath);

  final configFiles = await dir
      .list()
      .where((entity) =>
          entity is File && path.extension(entity.path) == '.json')
      .cast<File>()
      .toList();

  if (configFiles.isEmpty) {
    return null;
  }

  // Sort the files by last modified time descending
  configFiles.sort((a, b) =>
      b.lastModifiedSync().compareTo(a.lastModifiedSync()));

  // Return the name of the most recently modified config
  return path.basenameWithoutExtension(configFiles.first.path);
}


}