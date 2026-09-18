/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gitjournal/design/tokens/color_tokens.dart';

import 'settings/settings.dart';

class Themes {
  static final _pageTransitions = const PageTransitionsTheme(builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
  });

  static final _light = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: gjSeedPrimary,
      secondary: gjSeedSecondary,
    ),
    useMaterial3: true,
  ).copyWith(
    pageTransitionsTheme: _pageTransitions,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: gjGreenPrimaryDark,
      selectionHandleColor: gjGreenPrimary,
      selectionColor: gjSelectionLight,
    ),
  );

  static final _dark = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: gjSeedPrimary,
      secondary: gjSeedSecondary,
    ),
    useMaterial3: true,
  ).copyWith(
    pageTransitionsTheme: _pageTransitions,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: gjGreenPrimary,
      selectionHandleColor: gjGreenPrimary,
      selectionColor: gjLimeAccent,
    ),
  );

  static ThemeData fromName(String name) {
    switch (name) {
      case DEFAULT_LIGHT_THEME_NAME:
        return _light;
      case DEFAULT_DARK_THEME_NAME:
        return _dark;
      default:
        throw Exception("Theme not found - $name");
    }
  }
}
