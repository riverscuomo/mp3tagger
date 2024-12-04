// config_editor.dart

import 'package:flutter/material.dart';
import '../models/section_model.dart';
import '../services/config_service.dart';

class ConfigEditor extends StatefulWidget {
  final String configName;
  final Map<String, dynamic> configData;

  const ConfigEditor({
    Key? key,
    required this.configName,
    required this.configData,
  }) : super(key: key);

  @override
  _ConfigEditorState createState() => _ConfigEditorState();
}

class _ConfigEditorState extends State<ConfigEditor> {
  late List<SectionModel> sections;

  @override
  void initState() {
    super.initState();
    // Initialize sections from configData
    sections = (widget.configData['sections'] as List)
        .map((data) => SectionModel.fromJson(data))
        .toList();
  }

  void _addSection() {
    setState(() {
      sections.add(SectionModel(
        label: 'New Section',
        scales: [],
        noBlanks: false,
        groupControl: ScaleValue.neutral,
      ));
    });
  }

  void _addScaleToSection(SectionModel section) {
    setState(() {
      section.scales.add(ScaleItem(
        label: 'New Scale',
        value: ScaleValue.neutral,
        troughColor: Colors.grey,
      ));
    });
  }

  void _saveConfig() async {
    // Prepare config data
    final configData = {
      'sections': sections.map((section) => section.toJson()).toList(),
      // Include other config parameters if needed
    };

    await ConfigService.saveConfig(widget.configName, configData);
    Navigator.pop(context, true); // Return true to indicate changes were saved
  }

  void _cancelEditing() {
    Navigator.pop(context, false); // Return false to indicate no changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _cancelEditing,
          ),
        ],
      ),
      body: ListView(
        children: [
          ...sections.map((section) => _buildSectionTile(section)).toList(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Section'),
            onTap: _addSection,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(SectionModel section) {
    return ExpansionTile(
      key: Key(section.label),
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: section.label),
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (value) {
                section.label = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Confirm before deleting
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Section'),
                  content: Text('Are you sure you want to delete "${section.label}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          sections.remove(section);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      children: [
        ...section.scales.map((scale) => _buildScaleTile(section, scale)).toList(),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Scale'),
          onTap: () {
            _addScaleToSection(section);
          },
        ),
      ],
    );
  }

  Widget _buildScaleTile(SectionModel section, ScaleItem scale) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: scale.label),
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (value) {
                scale.label = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Confirm before deleting
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Scale'),
                  content: Text('Are you sure you want to delete "${scale.label}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          section.scales.remove(scale);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
