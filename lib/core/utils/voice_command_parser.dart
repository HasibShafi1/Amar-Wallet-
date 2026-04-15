/// Detects voice commands from speech input before sending to AI.
enum VoiceCommandType { none, undo, stopContinuous }

class VoiceCommand {
  final VoiceCommandType type;
  const VoiceCommand(this.type);

  bool get isCommand => type != VoiceCommandType.none;
}

class VoiceCommandParser {
  static const _undoPhrases = [
    'undo', 'undo last', 'cancel last', 'cancel', 'delete last', 'remove last',
  ];
  static const _stopPhrases = [
    'stop', 'done', 'finish', "that's all", 'thats all', 'ok done', 'exit',
  ];

  static VoiceCommand parse(String text) {
    final lower = text.toLowerCase().trim();

    if (_undoPhrases.contains(lower)) {
      return const VoiceCommand(VoiceCommandType.undo);
    }
    if (_stopPhrases.contains(lower)) {
      return const VoiceCommand(VoiceCommandType.stopContinuous);
    }
    return const VoiceCommand(VoiceCommandType.none);
  }
}
