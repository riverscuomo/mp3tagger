// widgets/config_manager.dart

import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ConfigManager extends StatefulWidget {
  final String currentConfig;
  final void Function(String configName, Map<String, dynamic> configData)
      onConfigLoaded;
  final VoidCallback onSaveConfig;

  const ConfigManager({
    Key? key,
    required this.currentConfig,
    required this.onConfigLoaded,
    required this.onSaveConfig,
  }) : super(key: key);

  @override
  State<ConfigManager> createState() => _ConfigManagerState();
}

class _ConfigManagerState extends State<ConfigManager> {
  late String _selectedConfig;
  List<String> _availableConfigs = [];
  final TextEditingController _newConfigNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedConfig = widget.currentConfig;
    _loadAvailableConfigs();
  }

  @override
  void didUpdateWidget(covariant ConfigManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentConfig != widget.currentConfig) {
      setState(() {
        _selectedConfig = widget.currentConfig;
      });
    }
  }

  Future<void> _loadAvailableConfigs() async {
    final configs = await ConfigService.getAvailableConfigs();
    setState(() {
      _availableConfigs = configs;
    });
  }

  Future<void> _createNewConfig(String name) async {
    if (name.isEmpty) return;

    if (_availableConfigs.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A configuration with this name already exists')),
      );
      return;
    }

    try {
      // Create new config with current settings
      final configData = {
        'sections': [], // Start with empty sections or clone current sections
        'bpmRange': [80.0, 100.0],
        'includeBpm': true,
        'excludeHold': true,
        'excludeDeselect': true,
      };
      await ConfigService.saveConfig(name, configData);
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
          // widgets/config_manager.dart

          onChanged: (String? newValue) async {
            if (newValue != null) {
              final config = await ConfigService.loadConfig(newValue);
              setState(() {
                _selectedConfig = newValue;
              });
              widget.onConfigLoaded(
                  newValue, config); // Pass both the config name and data
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            widget.onSaveConfig(); // Use the passed callback
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _availableConfigs.length <= 1
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Configuration'),
                      content: Text(
                          'Are you sure you want to delete "${_selectedConfig}"?'),
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
                              final config = await ConfigService.loadConfig(
                                  _availableConfigs[0]);
                              setState(() {
                                _selectedConfig = _availableConfigs[0];
                              });
                              widget.onConfigLoaded( // Pass both the config name and data
                                  _availableConfigs[0], config);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
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

        // IconButton(
        //   icon: const Icon(Icons.delete),
        //   onPressed: _availableConfigs.length <= 1
        //       ? null
        //       : () {
        //           showDialog(
        //             context: context,
        //             builder: (context) => AlertDialog(
        //               title: const Text('Delete Configuration'),
        //               content: Text(
        //                   'Are you sure you want to delete "${_selectedConfig}"?'),
        //               actions: [
        //                 TextButton(
        //                   onPressed: () => Navigator.pop(context),
        //                   child: const Text('Cancel'),
        //                 ),
        //                 TextButton(
        //                   onPressed: () async {
        //                     await ConfigService.deleteConfig(_selectedConfig);
        //                     await _loadAvailableConfigs();
        //                     if (_availableConfigs.isNotEmpty) {
        //                       final config = await ConfigService.loadConfig(
        //                           _availableConfigs[0]);
        //                       setState(() {
        //                         _selectedConfig = _availableConfigs[0];
        //                       });
        //                       widget.onConfigLoaded(
        //                           config); // Pass the updated config
        //                     }
        //                     if (mounted) Navigator.pop(context);
        //                   },
        //                   child: const Text('Delete',
        //                       style: TextStyle(color: Colors.red)),
        //                 ),
        //               ],
        //             ),
        //           );
        //         },
        // ),