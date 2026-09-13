#!/usr/bin/env dart
// SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
// SPDX-FileCopyrightText: 2026 Shubham Sharma
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

/// Keys that must always exist so the app compiles without secrets.
const _defaultKeys = <String>[
  'sentry',
  'supabaseUrl',
  'supabaseAnonKey',
  'revenueCatApiKey',
  'githubClientId',
  'githubClientSecret',
];

Future<int> main(List<String> args) async {
  var config = <String, String?>{};

  try {
    var contents = await File('secrets/env.json').readAsString();
    config = (json.decode(contents) as Map).map(
      (key, value) => MapEntry(key.toString(), value?.toString()),
    );
  } catch (ex) {
    stderr.writeln(ex);
  }

  // Ensure required keys always exist (empty string when missing)
  for (final key in _defaultKeys) {
    config.putIfAbsent(key, () => null);
  }

  if (args.isNotEmpty) {
    config = config.map((key, value) => MapEntry(key, null));
  }

  stderr.writeln(config);
  stderr.writeln('');

  var contents = 'class Env {\n';
  config.forEach((key, value) {
    if (value == null) {
      contents += '  static final String $key = "";\n';
    } else {
      // Escape any quotes in the value
      final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      contents += '  static final String $key = "$escaped";\n';
    }
  });
  contents += '}\n';

  stderr.writeln(contents);

  const filename = 'lib/.env.dart';
  await File(filename).writeAsString(contents);

  return 0;
}
