import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/accessibility_palettes.dart';
import 'repository_providers.dart';

class AccessibilityModeNotifier extends StateNotifier<AccessibilityMode> {
  final Ref ref;

  AccessibilityModeNotifier(this.ref) : super(AccessibilityMode.defaultNight) {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final modeStr = await prefs.getAccessibilityMode();
    state = _stringToMode(modeStr);
  }

  Future<void> setMode(AccessibilityMode mode) async {
    state = mode;
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setAccessibilityMode(_modeToString(mode));
  }

  String _modeToString(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.defaultNight:
        return 'defaultNight';
      case AccessibilityMode.deuteranopia:
        return 'deuteranopia';
      case AccessibilityMode.protanopia:
        return 'protanopia';
      case AccessibilityMode.tritanopia:
        return 'tritanopia';
      case AccessibilityMode.monochrome:
        return 'monochrome';
    }
  }

  AccessibilityMode _stringToMode(String str) {
    switch (str) {
      case 'deuteranopia':
        return AccessibilityMode.deuteranopia;
      case 'protanopia':
        return AccessibilityMode.protanopia;
      case 'tritanopia':
        return AccessibilityMode.tritanopia;
      case 'monochrome':
        return AccessibilityMode.monochrome;
      default:
        return AccessibilityMode.defaultNight;
    }
  }
}

final accessibilityModeProvider = StateNotifierProvider<AccessibilityModeNotifier, AccessibilityMode>((ref) {
  return AccessibilityModeNotifier(ref);
});
