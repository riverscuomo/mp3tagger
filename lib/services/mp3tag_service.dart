import 'dart:ffi';
import 'package:win32/win32.dart';

import 'dart:io';

void runPythonScript(String filterText) async {
  // final result = await Process.run('python', ['assets/automate.exe', filterText]);
  const scriptPath = 'assets/automate.exe';
  final result = await Process.run(scriptPath, [filterText]);


  if (result.exitCode == 0) {
    print('Script executed successfully.');
  } else {
    print('Error: ${result.stderr}');
  }
}


class MP3TagService {
  static Future<void> applyFilter(String filter) async {
    runPythonScript(filter);
    return;
    try {
      // Find MP3Tag window
      final hwnd = FindWindow(
        
        nullptr,
        TEXT('Mp3tag v3.05'),
      );
      
      if (hwnd == 0) {
        throw Exception('MP3Tag window not found');
      }

      // Bring window to front
      SetForegroundWindow(hwnd);
      
      // Find filter combobox
      final comboHwnd = FindWindowEx(
        hwnd,
        NULL,
        TEXT('ComboBox'),
        nullptr,
      );
      
      if (comboHwnd == 0) {
        throw Exception('Filter ComboBox not found');
      }

      // Prepare filter text
      filter = filter
        .replaceAll(')', '{)}')
        .replaceAll('(', '{(}')
        .replaceAll(' ', '{ }')
        .replaceAll('%', '{%}');

      // Select all existing text
      final emptyStr = TEXT('');
      SendMessage(comboHwnd, WM_SETTEXT, 0, emptyStr.address);
      
      // Type new filter text
      final filterStr = TEXT(filter);
      SendMessage(comboHwnd, WM_SETTEXT, 0, filterStr.address);

    } catch (e) {
      print('Error applying filter: $e');
      rethrow;
    }
  }

  static String getBpmFilter(List<double> bpmRange) {
    final bpmLow = bpmRange[0].round();
    final bpmHi = bpmRange[1].round();
    
    var filter = '((NOT BPM LESS $bpmLow AND NOT BPM GREATER $bpmHi)';
    
    // Secondary BPM range (doubled or halved)
    final bpmLow2 = bpmLow > 80 ? (bpmLow / 2).round() : (bpmLow * 2).round();
    final bpmHi2 = bpmLow > 80 ? (bpmHi / 2).round() : (bpmHi * 2).round();
    
    filter += ' OR (NOT BPM LESS $bpmLow2 AND NOT BPM GREATER $bpmHi2)) AND ';
    
    return filter;
  }

  static String cleanFilter(String filter) {
    return filter
      .trim()
      .replaceAll(RegExp(r'^\s*(AND|OR)\s*'), '')
      .replaceAll(RegExp(r'\s*(AND|OR)\s*$'), '')
      .trim();
  }
}