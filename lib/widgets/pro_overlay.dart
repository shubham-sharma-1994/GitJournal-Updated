/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: 2026 Shubham Sharma
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

/// Pro features are unlocked — always show the child.
class ProOverlay extends StatelessWidget {
  final Widget child;

  const ProOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
