/*
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/animation.dart';

/// Material 3 motion tokens (durations + easing).

const Duration durationShort1 = Duration(milliseconds: 50);
const Duration durationShort2 = Duration(milliseconds: 100);
const Duration durationShort3 = Duration(milliseconds: 150);
const Duration durationShort4 = Duration(milliseconds: 200);

const Duration durationMedium1 = Duration(milliseconds: 250);
const Duration durationMedium2 = Duration(milliseconds: 300);
const Duration durationMedium3 = Duration(milliseconds: 350);
const Duration durationMedium4 = Duration(milliseconds: 400);

const Duration durationLong1 = Duration(milliseconds: 450);
const Duration durationLong2 = Duration(milliseconds: 500);
const Duration durationLong3 = Duration(milliseconds: 550);
const Duration durationLong4 = Duration(milliseconds: 600);

/// M3 standard easing approximations.
const Curve curveStandard = Curves.easeInOut;
const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;
const Curve curveDecelerated = Curves.easeOut;
const Curve curveAccelerated = Curves.easeIn;
const Curve curveLinear = Curves.linear;
