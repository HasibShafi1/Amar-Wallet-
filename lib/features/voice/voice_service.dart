import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final voiceServiceProvider =
    NotifierProvider<VoiceServiceNotifier, VoiceState>(VoiceServiceNotifier.new);

// ─── State ────────────────────────────────────────────────────────────────────
class VoiceState {
  final bool isListening;
  final String currentText;
  final bool hasError;
  final String errorMessage;
  final bool isContinuousMode;

  const VoiceState({
    this.isListening = false,
    this.currentText = '',
    this.hasError = false,
    this.errorMessage = '',
    this.isContinuousMode = false,
  });

  VoiceState copyWith({
    bool? isListening,
    String? currentText,
    bool? hasError,
    String? errorMessage,
    bool? isContinuousMode,
  }) =>
      VoiceState(
        isListening: isListening ?? this.isListening,
        currentText: currentText ?? this.currentText,
        hasError: hasError ?? this.hasError,
        errorMessage: errorMessage ?? this.errorMessage,
        isContinuousMode: isContinuousMode ?? this.isContinuousMode,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class VoiceServiceNotifier extends Notifier<VoiceState> {
  SpeechToText _stt = SpeechToText();
  Future<bool>? _initFuture; // guard: only one init runs at a time
  bool _available = false;

  @override
  VoiceState build() {
    _ensureInit(); // warm up eagerly
    return const VoiceState();
  }

  Future<bool> _ensureInit() {
    _initFuture ??= _runInit();
    return _initFuture!;
  }

  Future<bool> _runInit() async {
    _available = false;
    try {
      _stt = SpeechToText();
      _available = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );
      if (_available) {
        // Let Android's SpeechRecognizer fully connect before first listen()
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (state.isListening) {
        state = state.copyWith(isListening: false);
      }
    }
  }

  void _onError(dynamic error) {
    final code = (error.errorMsg as String?) ?? '';

    // User paused / said nothing — non-fatal
    if (code == 'error_no_match' || code == 'error_speech_timeout') {
      state = state.copyWith(isListening: false, currentText: '');
      return;
    }

    // Android recognizer in bad state — reset silently, user can tap again
    if (code == 'error_client' || code == 'error_recognizer_busy') {
      state = state.copyWith(isListening: false, isContinuousMode: false, currentText: '');
      _available = false;
      _initFuture = null;
      return;
    }

    state = state.copyWith(
      isListening: false,
      isContinuousMode: false,
      currentText: '',
      hasError: true,
      errorMessage: _friendly(code),
    );
  }

  String _friendly(String code) {
    switch (code) {
      case 'error_permission':
        return 'Microphone permission denied.\nGo to Settings → Apps → Amar Wallet → Permissions → Microphone.';
      case 'error_audio':
        return 'Cannot access microphone. Close other apps using it.';
      case 'error_network':
        return 'No internet. Speech recognition needs a connection.';
      case 'error_server':
        return 'Google speech server error. Try again.';
      default:
        return 'Voice error ($code). Tap mic to try again.';
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Start listening with optional locale (e.g. 'en_US', 'bn_BD')
  Future<void> startListening({
    bool continuous = false,
    String localeId = 'en_US',
  }) async {
    state = VoiceState(isContinuousMode: continuous);

    final ok = await _ensureInit();
    if (!ok) {
      state = state.copyWith(
        hasError: true,
        errorMessage:
            'Speech recognition unavailable.\nEnsure Google app is installed and updated.',
      );
      return;
    }

    if (_stt.isListening) {
      await _stt.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    state = state.copyWith(isListening: true, currentText: '');

    await _stt.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        enableHapticFeedback: false,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
    state = state.copyWith(isListening: false, isContinuousMode: false, currentText: '');
  }

  void clearText() => state = state.copyWith(currentText: '');

  void _onResult(SpeechRecognitionResult result) {
    state = state.copyWith(
      currentText: result.recognizedWords,
      isListening: !result.finalResult,
    );
  }

  /// Get available locales from the STT engine
  Future<List<LocaleName>> getAvailableLocales() async {
    await _ensureInit();
    if (!_available) return [];
    return _stt.locales();
  }
}
