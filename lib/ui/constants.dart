import 'package:flutter/material.dart';

const appTitle = 'Simplified Unidirectional Data Flow';

/// A [CircularProgressIndicator] centered on the screen.
const spinner = Center(child: CircularProgressIndicator());

/// Standard spacing values
class Spacing {
  /// Extra extra small
  static const xxs = 4.0;

  /// Extra small
  static const xs = 8.0;

  /// Small
  static const sm = 12.0;

  /// Medium
  static const md = 16.0;

  /// Large
  static const lg = 24.0;
}

/// Standard border radius values
class Radiuses {
  static const sm = 8;
  static const md = 12;
  static const lg = 16;
}

/// Standard icon sizes
class IconSizes {
  /// Extra small
  static const sm = 24.0;

  /// Small
  static const md = 32.0;

  /// Medium
  static const lg = 64.0;
}
