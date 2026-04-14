import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final voiceServiceProvider = NotifierProvider<VoiceServiceNotifier, VoiceState>(() {
  return VoiceServiceNotifier();
});

class VoiceState {
  final bool isListening;
  final String currentText;
  final bool hasError;
  final String errorMessage;

  VoiceState({
    this.isListening = false,
    this.currentText = '',
    this.hasError = false,
    this.errorMessage = '',
  });

  VoiceState copyWith({
    bool? isListening,
    String? currentText,
    bool? hasError,
    String? errorMessage,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      currentText: currentText ?? this.currentText,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceServiceNotifier extends Notifier<VoiceState> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  VoiceState build() {
    _initSpeech();
    return VoiceState();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => state = state.copyWith(hasError: true, errorMessage: error.errorMsg),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: "Failed to initialize speech to text");
    }
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }
    
    if (_speechEnabled) {
      state = state.copyWith(isListening: true, currentText: '', hasError: false, errorMessage: '');
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation),
      );
    } else {
      state = state.copyWith(hasError: true, errorMessage: "Speech recognition is not available.");
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    state = state.copyWith(currentText: result.recognizedWords);
  }
}
