import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

/// Text-to-Speech service for accessibility navigation
/// IMPORTANT: Only speak at key moments (screen entry, milestones, actions)
/// NEVER speak every tap or during scrolling
class TtsService {
  final Logger _logger = Logger();
  FlutterTts? _tts;
  bool _isEnabled = false;
  double _rate = 0.5; // 0.5 = slow, 1.0 = normal

  bool get isEnabled => _isEnabled;
  double get rate => _rate;

  /// Initialize TTS
  Future<void> initialize({bool enabled = false, double rate = 0.5}) async {
    _isEnabled = enabled;
    _rate = rate;

    if (_isEnabled) {
      await _initializeTts();
    }
  }

  Future<void> _initializeTts() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(_rate);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
      _logger.i('TTS initialized');
    } catch (e) {
      _logger.e('Failed to initialize TTS', error: e);
    }
  }

  /// Enable TTS
  Future<void> enable() async {
    if (_isEnabled) return;
    _isEnabled = true;
    await _initializeTts();
  }

  /// Disable TTS
  Future<void> disable() async {
    _isEnabled = false;
    await _tts?.stop();
  }

  /// Set speech rate
  Future<void> setRate(double rate) async {
    _rate = rate;
    await _tts?.setSpeechRate(rate);
  }

  /// Speak text (if enabled)
  Future<void> speak(String text) async {
    if (!_isEnabled || _tts == null || text.isEmpty) return;

    try {
      await _tts!.speak(text);
    } catch (e) {
      _logger.e('TTS speak failed', error: e);
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    await _tts?.stop();
  }

  // ========== Specialized Speaking Methods ==========

  /// Speak screen entry summary (called once on screen load)
  /// Example: "Home screen. 3 suggested workouts."
  Future<void> speakScreenSummary(String screenName, {String? details}) async {
    final text = details != null
        ? '$screenName screen. $details'
        : '$screenName screen';
    await speak(text);
  }

  /// Speak action confirmation
  /// Example: "Workout added to calendar"
  Future<void> speakAction(String action) async {
    await speak(action);
  }

  /// Speak session milestone
  /// Example: "Halfway there! Keep going."
  Future<void> speakMilestone(String milestone) async {
    await speak(milestone);
  }

  /// Speak error or warning
  Future<void> speakError(String error) async {
    await speak('Error: $error');
  }

  /// Speak validation message
  Future<void> speakValidation(String message) async {
    await speak(message);
  }

  // ========== Pre-defined Common Phrases ==========

  Future<void> speakWorkoutStarted(String workoutName) async {
    await speak('Starting $workoutName');
  }

  Future<void> speakWorkoutCompleted() async {
    await speak('Workout completed! Great job.');
  }

  Future<void> speakHalfwayMilestone() async {
    await speak('Halfway there! Keep going.');
  }

  Future<void> speakTenMinutesRemaining() async {
    await speak('10 minutes remaining');
  }

  Future<void> speakFiveMinutesRemaining() async {
    await speak('5 minutes remaining');
  }

  Future<void> speakOneMinuteRemaining() async {
    await speak('1 minute remaining');
  }

  Future<void> speakNextExercise(String exerciseName) async {
    await speak('Next: $exerciseName');
  }

  Future<void> speakRestTime(int seconds) async {
    await speak('Rest for $seconds seconds');
  }

  Future<void> speakNavigatedTo(String destination) async {
    await speak('Navigated to $destination');
  }

  /// Dispose TTS
  Future<void> dispose() async {
    await _tts?.stop();
    _tts = null;
  }
}
