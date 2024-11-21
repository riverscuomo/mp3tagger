import 'package:flutter/material.dart';
import 'package:mp3tagger/services/config_service.dart';
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
  bool _excludeHold = true;
  bool _excludeDeselect = true;
  late List<SectionModel> sections = [];
  String currentConfig = 'forJake';  // Default config

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ConfigService.initializeDefaultConfigs();
    final config = await ConfigService.loadConfig(currentConfig);
    _loadConfig(config);
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
          const SnackBar(content: Text('MP3TAG_PATH environment variable not set')),
        );
      }
    }
  }

  void _loadConfig(List<Map<String, dynamic>> config) {
    setState(() {
      sections = config.map((data) => SectionModel.fromJson(data)).toList();
      // sort sections by label, case insensitive
      sections.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    });
    _updateFilter();
  }

// This method now handles saving the current configuration
Future<void> _saveCurrentConfig() async {
  final configData = sections.map((section) => section.toJson()).toList();
  await ConfigService.saveConfig(currentConfig, configData);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Configuration saved successfully')),
  );
}

Widget _buildConfigTools() {
  return ConfigManager(
    currentConfig: currentConfig,
    onConfigLoaded: (configData) {
      setState(() {
        currentConfig = currentConfig;
        sections = configData.map((data) => SectionModel.fromJson(data)).toList();
        sections.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      });
      _updateFilter();
    },
    onSaveConfig: _saveCurrentConfig, // Pass the save method as a callback
  );
}

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _launchMP3Tag() async {
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
    }
  }

  String getBpmFilter(List<double> bpmRange) {
    return MP3TagService.getBpmFilter(bpmRange);
  }

  String getFilterFromSection(String currentFilter, SectionModel section, bool controlTogglePressed) {
    return currentFilter + section.getFilter(controlTogglePressed: controlTogglePressed);
  }

  String cleanFilter(String filter) {
    return MP3TagService.cleanFilter(filter);
  }

  void _updateFilter() {
    String filter = '';
    
    if (_includeBpm) {
      filter = getBpmFilter(_bpmRange);
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


// Widget _buildConfigTools() {
//     return ConfigManager(
//       currentConfig: currentConfig,  // This is just the name (String)
//       onConfigLoaded: (configData) {
//         setState(() {
//           // Update the current config name
//           currentConfig = currentConfig;
//           // Load the actual config data
//           sections = configData.map((data) => SectionModel.fromJson(data)).toList();
//           // sort sections by label, case insensitive
//       sections.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
//         });
//         _updateFilter();
//       },
//     );
//   }

  Widget _buildControlPanel() {
    return Container(
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          _buildCheckbox(
            'Include BPM',
            _includeBpm,
            (value) => setState(() {
              _includeBpm = value ?? false;
              _updateFilter();
            }),
          ),
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
          SizedBox(
            width: 600,
            child: TextField(
              controller: _filterController,
              maxLines: 8,
              style: filterTextStyle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF444444),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
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
            width: 300,
            child: _buildControlPanel(),
          ),
        ],
      ),
    ),
  );
}


}