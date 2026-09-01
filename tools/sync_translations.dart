#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final force = args.contains('--force') || args.contains('-f');
  final scriptUri = Platform.script;
  final String projectRoot;
  if (scriptUri.scheme == 'file') {
    projectRoot = File(scriptUri.toFilePath()).parent.parent.path;
  } else {
    projectRoot = Directory.current.path;
  }

  final enPath = '$projectRoot/${translationFiles['en']!}';
  print('Loading source of truth: $enPath');
  final enJson = await loadJson(enPath);

  if (enJson.isEmpty) {
    print('Error: en.json is empty or not found at $enPath.');
    exitCode = 1;
    return;
  }

  // Load git base version of en.json to detect changed English strings automatically
  Map<String, dynamic> gitEnJson = {};
  if (!force) {
    gitEnJson = await loadGitEnJson(projectRoot, translationFiles['en']!);
    if (gitEnJson.isNotEmpty) {
      print('Loaded git baseline for en.json to automatically detect modified strings.');
    }
  } else {
    print('Running in FORCE mode: All keys will be re-translated.');
  }

  for (final entry in translationFiles.entries) {
    final lang = entry.key;
    final relativePath = entry.value;
    final path = '$projectRoot/$relativePath';

    if (lang == 'en') continue;

    print('\n----------------------------------------');
    print('Syncing $lang ($path) with en.json...');

    final targetJson = await loadJson(path);
    final stats = SyncStats();
    final syncedJson = await syncMap(
      enJson,
      targetJson,
      gitEnJson,
      lang,
      stats,
      force: force,
    );

    await saveJson(path, syncedJson);
    print('Finished syncing $lang. Saved to $path.');
    print('Statistics for $lang:');
    print('  - Added / Updated (Translated): ${stats.added}');
    print('  - Deleted (Obsolete): ${stats.deleted}');
    print('  - Untouched (Existing): ${stats.untouched}');
    if (stats.failed > 0) {
      print('  - Failed: ${stats.failed}');
    }
  }

  print('\n----------------------------------------');
  print('All translation files are now synchronized!');
}

class SyncStats {
  int added = 0;
  int deleted = 0;
  int untouched = 0;
  int failed = 0;
}

final translationFiles = {
  'en': 'assets/lang/en.json',
  'gu': 'assets/lang/gu.json',
  'hi': 'assets/lang/hi.json',
};

Future<String> translate(String text, String lang) async {
  final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$lang&dt=t&q=${Uri.encodeComponent(text)}');

  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    final buffer = StringBuffer();
    if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
      for (final part in decoded[0]) {
        if (part is List && part.isNotEmpty && part[0] is String) {
          buffer.write(part[0]);
        }
      }
    }
    return buffer.toString().isNotEmpty ? buffer.toString() : decoded[0][0][0];
  } finally {
    httpClient.close();
  }
}

Future<Map<String, dynamic>> loadJson(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return {};
  }
  final content = await file.readAsString();
  return jsonDecode(content);
}

Future<Map<String, dynamic>> loadGitEnJson(String projectRoot, String relativePath) async {
  try {
    final result = await Process.run('git', ['show', 'HEAD:$relativePath'], workingDirectory: projectRoot);
    if (result.exitCode == 0 && result.stdout is String && (result.stdout as String).isNotEmpty) {
      return jsonDecode(result.stdout as String);
    }
  } catch (_) {}
  return {};
}

Future<void> saveJson(String path, Map<String, dynamic> data) async {
  final file = File(path);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(data)}\n');
}

Future<Map<String, dynamic>> syncMap(
  Map<String, dynamic> source,
  Map<String, dynamic> target,
  Map<String, dynamic> baseSource,
  String lang,
  SyncStats stats, {
  bool force = false,
  String currentPath = '',
}) async {
  final result = <String, dynamic>{};

  // Identify deleted (obsolete) keys
  for (final key in target.keys) {
    if (!source.containsKey(key)) {
      stats.deleted++;
      final fullPath = currentPath.isEmpty ? key : '$currentPath.$key';
      print('  Obsolete key found in $lang (will be deleted): "$fullPath"');
    }
  }

  for (final key in source.keys) {
    final sourceVal = source[key];
    final targetVal = target[key];
    final baseSourceVal = baseSource[key];
    final fullPath = currentPath.isEmpty ? key : '$currentPath.$key';

    if (sourceVal is Map<String, dynamic>) {
      final targetMap = (targetVal is Map<String, dynamic>) ? targetVal : <String, dynamic>{};
      final baseMap = (baseSourceVal is Map<String, dynamic>) ? baseSourceVal : <String, dynamic>{};
      result[key] = await syncMap(
        sourceVal,
        targetMap,
        baseMap,
        lang,
        stats,
        force: force,
        currentPath: fullPath,
      );
    } else if (sourceVal is String) {
      final isNewOrEmpty = targetVal == null || (targetVal is String && targetVal.trim().isEmpty);
      final hasSourceChanged = baseSource.isNotEmpty && baseSourceVal is String && baseSourceVal != sourceVal;
      final needsTranslation = force || isNewOrEmpty || hasSourceChanged;

      if (!needsTranslation && targetVal is String) {
        result[key] = targetVal;
        stats.untouched++;
      } else {
        final reason = force
            ? 'force'
            : isNewOrEmpty
                ? 'new'
                : 'source updated ("$baseSourceVal" -> "$sourceVal")';
        print('Translating [$reason] "$fullPath": "$sourceVal" -> [$lang]...');
        try {
          final translated = await translate(sourceVal, lang);
          result[key] = translated;
          print('  Result: "$translated"');
          stats.added++;
        } catch (e) {
          print('  Error translating "$sourceVal": $e');
          result[key] = targetVal ?? sourceVal;
          stats.failed++;
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } else {
      result[key] = sourceVal;
    }
  }

  return result;
}
