// widgets/config_manager.dart

import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ConfigManager extends StatefulWidget {
  final String currentConfig;
  final Function(List<Map<String, dynamic>>) onConfigLoaded;

  const ConfigManager({
    super.key,
    required this.currentConfig,
    required this.onConfigLoaded,
  });

  @override
  State<ConfigManager> createState() => _ConfigManagerState();
}

class _ConfigManagerState extends State<ConfigManager> {
  late String _selectedConfig;
  List<String> _availableConfigs = [];
  final TextEditingController _newConfigNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedConfig = widget.currentConfig;
    _loadAvailableConfigs();
  }

  Future<void> _loadAvailableConfigs() async {
    final configs = await ConfigService.getAvailableConfigs();
    setState(() {
      _availableConfigs = configs;
    });
  }

  Future<void> _saveCurrentConfig(List<Map<String, dynamic>> config) async {
    try {
      await ConfigService.saveConfig(_selectedConfig, config);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration: $e')),
      );
    }
  }

  Future<void> _createNewConfig(String name) async {
    if (name.isEmpty) return;

    if (_availableConfigs.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A configuration with this name already exists')),
      );
      return;
    }

    try {
      // Create new config with current settings
      await ConfigService.saveConfig(name, []); // Empty config to start
      await _loadAvailableConfigs();
      setState(() {
        _selectedConfig = name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating configuration: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: _selectedConfig,
          items: _availableConfigs.map((String config) {
            return DropdownMenuItem<String>(
              value: config,
              child: Text(config),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              final config = await ConfigService.loadConfig(newValue);
              setState(() {
                _selectedConfig = newValue;
              });
              widget.onConfigLoaded(config);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('New Configuration'),
                content: TextField(
                  controller: _newConfigNameController,
                  decoration: const InputDecoration(
                    labelText: 'Configuration Name',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _createNewConfig(_newConfigNameController.text);
                      Navigator.pop(context);
                      _newConfigNameController.clear();
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            // You'll need to pass the current configuration here
            // _saveCurrentConfig(currentConfig);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _availableConfigs.length <= 1 ? null : () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Configuration'),
                content: Text('Are you sure you want to delete "${_selectedConfig}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ConfigService.deleteConfig(_selectedConfig);
                      await _loadAvailableConfigs();
                      if (_availableConfigs.isNotEmpty) {
                        final config = await ConfigService.loadConfig(_availableConfigs[0]);
                        setState(() {
                          _selectedConfig = _availableConfigs[0];
                        });
                        widget.onConfigLoaded(config);
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}