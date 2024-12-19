import 'package:flutter/material.dart';
import 'package:mp3tagger/services/config_service.dart';
import 'package:mp3tagger/widgets/config_editor.dart';
import 'package:mp3tagger/widgets/config_manager.dart';
import 'dart:io';
import 'package:process_run/process_run.dart';
import 'constants.dart';
import 'sections.dart';
import 'models/section_model.dart';
import 'widgets/custom_slider.dart';
import 'widgets/section_widget.dart';
import 'services/mp3tag_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MP3TaggerApp());
}

class MP3TaggerApp extends StatelessWidget {
  const MP3TaggerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP3 Tagger',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const MP3TaggerHome(),
    );
  }
}

class MP3TaggerHome extends StatefulWidget {
  const MP3TaggerHome({Key? key}) : super(key: key);

  @override
  _MP3TaggerHomeState createState() => _MP3TaggerHomeState();
}

class _MP3TaggerHomeState extends State<MP3TaggerHome> {
  final TextEditingController _filterController = TextEditingController();
  final List<double> _bpmRange = [80, 100];
  bool _includeBpm = true;
  final List<double> _cpmRange = [1, 100];
  bool _includeCpm = false; // Default to false
  bool _excludeHold = true;
  bool _excludeDeselect = true;
  late List<SectionModel> sections = [];
  String currentConfig = 'default'; // Default config

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

// main.dart

  Future<void> _initializeApp() async {
    // Ensure config directory exists
    await ConfigService.ensureConfigDirectoryExists();

    // Try to get the last modified config
    String? lastConfigName = await ConfigService.getLastModifiedConfigName();

    if (lastConfigName != null && lastConfigName.isNotEmpty) {
      setState(() {
        currentConfig = lastConfigName;
      });
      final config = await ConfigService.loadConfig(currentConfig);
      _loadConfig(config);
    } else {
      // No configs exist, load 'default' from assets
      setState(() {
        currentConfig = 'default';
      });
      final config = await ConfigService.loadConfigFromAssets(currentConfig);
      _loadConfig(config);
    }
    await _launchMp3Tag();
  }

  Future<void> _launchMp3Tag() async {
    final mp3TagPath = Platform.environment['MP3TAG_PATH'];
    if (mp3TagPath != null) {
      try {
        await Process.start(mp3TagPath, []);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to launch MP3Tag: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('MP3TAG_PATH environment variable not set')),
        );
      }
    }
  }

  void _loadConfig(Map<String, dynamic> config) {
    setState(() {
      if (config.containsKey('sections')) {
        sections = (config['sections'] as List)
            .map((data) => SectionModel.fromJson(data))
            .toList();
        // Sort sections by label, case insensitive
        sections.sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      } else {
        sections = [];
      }
      if (config.containsKey('bpmRange')) {
        _bpmRange[0] = (config['bpmRange'] as List)[0];
        _bpmRange[1] = (config['bpmRange'] as List)[1];
      }
      // Load new CPM configuration
      if (config.containsKey('cpmRange')) {
        _cpmRange[0] = (config['cpmRange'] as List)[0];
        _cpmRange[1] = (config['cpmRange'] as List)[1];
      }
      if (config.containsKey('includeCpm')) {
        _includeCpm = config['includeCpm'];
      }
      if (config.containsKey('includeBpm')) {
        _includeBpm = config['includeBpm'];
      }
      if (config.containsKey('excludeHold')) {
        _excludeHold = config['excludeHold'];
      }
      if (config.containsKey('excludeDeselect')) {
        _excludeDeselect = config['excludeDeselect'];
      }
    });
    _updateFilter();
  }

  Future<void> _saveCurrentConfig() async {
    final configData = {
      'sections': sections.map((section) => section.toJson()).toList(),
      'bpmRange': _bpmRange,
      'includeBpm': _includeBpm,
      'cpmRange': _cpmRange,
      'includeCpm': _includeCpm,
      'excludeHold': _excludeHold,
      'excludeDeselect': _excludeDeselect,
    };
    await ConfigService.saveConfig(currentConfig, configData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved successfully')),
    );
  }

  Widget _buildConfigTools() {
    return ConfigManager(
      currentConfig: currentConfig,
      onConfigLoaded: (String configName, Map<String, dynamic> configData) {
        setState(() {
          currentConfig = configName; // Update currentConfig with the new name
        });
        _loadConfig(configData); // Load the configuration data
      },
      onSaveConfig: _saveCurrentConfig,
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  String getBpmFilter(List<double> bpmRange) {
    return MP3TagService.getBpmFilter(bpmRange);
  }

  // Implement the CPM filter string
  String getCpmFilter(List<double> cpmRange) {
   return MP3TagService.getCpmFilter(cpmRange);
  }

  String getFilterFromSection(
      String currentFilter, SectionModel section, bool controlTogglePressed) {
    return currentFilter +
        section.getFilter(controlTogglePressed: controlTogglePressed);
  }

  String cleanFilter(String filter) {
    return MP3TagService.cleanFilter(filter);
  }

  void _updateFilter() {
    String filter = '';

    if (_includeBpm) {
      filter = getBpmFilter(_bpmRange);
    }
    if (_includeCpm) {
      if (filter.isNotEmpty) {
        filter += ' AND ';
      }
      filter += getCpmFilter(_cpmRange);
    }

    for (var section in sections) {
      filter = getFilterFromSection(filter, section, false);
    }

    filter = cleanFilter(filter);
    filter = filter.replaceAll(' AND ', '\n');

    setState(() {
      _filterController.text = filter;
    });
  }

  Future<void> _applyFilter() async {
    String filter = _filterController.text.replaceAll('\n', ' AND ');
    if (_excludeHold) {
      filter += ' AND HOLD ABSENT';
    }
    if (_excludeDeselect) {
      filter += ' AND DESELECT ABSENT';
    }

    try {
      await MP3TagService.applyFilter(filter);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildControlPanel() {
    return Container(
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Load the current configuration data
              final configData = await ConfigService.loadConfig(currentConfig);
              // Navigate to ConfigEditor
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigEditor(
                    configName: currentConfig,
                    configData: configData,
                  ),
                ),
              );
              if (result == true) {
                // Reload configuration if changes were saved
                final updatedConfig =
                    await ConfigService.loadConfig(currentConfig);
                _loadConfig(updatedConfig);
              }
            },
          ),
          // Include BPM Checkbox
          _buildCheckbox(
            'Include BPM',
            _includeBpm,
            (value) => setState(() {
              _includeBpm = value ?? false;
              _updateFilter();
            }),
          ),
          // Conditionally display BPM controls
          if (_includeBpm) ...[
            const SizedBox(height: 16),
            const Text('BPM Range', style: headerTextStyle),
            const SizedBox(height: 8),
            SizedBox(
              width: 600,
              child: CustomSlider(
                values: _bpmRange,
                min: 55,
                max: 140,
                onChanged: (values) {
                  setState(() {
                    _bpmRange[0] = values[0];
                    _bpmRange[1] = values[1];
                  });
                  _updateFilter();
                },
              ),
            ),
          ],
          
           // New Include CPM Checkbox
          _buildCheckbox(
            'Include CPM',
            _includeCpm,
            (value) => setState(() {
              _includeCpm = value ?? false;
              _updateFilter();
            }),
          ),
          // Conditionally display CPM controls
          if (_includeCpm) ...[
            const SizedBox(height: 16),
            const Text('CPM Range', style: headerTextStyle),
            const SizedBox(height: 8),
            SizedBox(
              width: 600,
              child: CustomSlider(
                values: _cpmRange,
                min: 1,
                max: 100,
                onChanged: (values) {
                  setState(() {
                    _cpmRange[0] = values[0];
                    _cpmRange[1] = values[1];
                  });
                  _updateFilter();
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Other checkboxes
          _buildCheckbox(
            'Exclude Hold',
            _excludeHold,
            (value) => setState(() {
              _excludeHold = value ?? false;
              _updateFilter();
            }),
          ),
          _buildCheckbox(
            'Exclude Deselect',
            _excludeDeselect,
            (value) => setState(() {
              _excludeDeselect = value ?? false;
              _updateFilter();
            }),
          ),
          const SizedBox(height: 24),
          // Apply Filter Button
          ElevatedButton(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF476B6B),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'FILTER',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          // Filter TextField
          Expanded(
            child: SizedBox(
              width: 600,
              child: TextField(
                controller: _filterController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: filterTextStyle,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF444444),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(label, style: paramTextStyle),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController verticalScrollController = ScrollController();
    final ScrollController horizontalScrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MP3 Tagger'),
        actions: [
          _buildConfigTools(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable sections with both vertical and horizontal scrolling
            Expanded(
              child: Scrollbar(
                controller: verticalScrollController,
                thumbVisibility: true,
                thickness: 16.0, // Windows-style thickness
                child: SingleChildScrollView(
                  controller: verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: horizontalScrollController,
                    thumbVisibility: true,
                    thickness: 16.0, // Windows-style thickness
                    child: SingleChildScrollView(
                      controller: horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...sections.map((section) => SectionWidget(
                                  section: section,
                                  onChanged: _updateFilter,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Fixed spacing between sections and control panel
            const SizedBox(width: 32),

            // Fixed-width control panel
            SizedBox(
              width: 425,
              child: _buildControlPanel(),
            ),
          ],
        ),
      ),
    );
  }
}


  // Future<void> _launchMP3Tag() async {
  //   final mp3TagPath = Platform.environment['MP3TAG_PATH'];
  //   if (mp3TagPath != null) {
  //     try {
  //       await Process.start(mp3TagPath, []);
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Failed to launch MP3Tag: $e')),
  //         );
  //       }
  //     }
  //   }
  // }
