import 'package:flutter/foundation.dart';

// Temporary development access; removal is tracked in docs/TECHNICAL_DEBT.md.
bool demoModeForBuild({
  bool debugBuild = kDebugMode,
  bool requested = const bool.fromEnvironment('DEMO_MODE', defaultValue: true),
}) =>
    kDebugMode && debugBuild && requested;
