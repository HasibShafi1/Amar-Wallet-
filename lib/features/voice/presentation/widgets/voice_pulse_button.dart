import 'package:flutter/material.dart';

class VoicePulseButton extends StatefulWidget {
  final bool isListening;
  final bool isContinuous;
  final VoidCallback onTap;

  const VoicePulseButton({
    super.key,
    required this.isListening,
    this.isContinuous = false,
    required this.onTap,
  });

  @override
  State<VoicePulseButton> createState() => _VoicePulseButtonState();
}

class _VoicePulseButtonState extends State<VoicePulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut);
    if (widget.isListening) _pulseCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant VoicePulseButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening != old.isListening) {
      if (widget.isListening) {
        _pulseCtrl.repeat();
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final primaryContainer = cs.primaryContainer;
    final isRec = widget.isListening || widget.isContinuous;
    final accentColor = widget.isContinuous ? Colors.red.shade700 : primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              if (widget.isListening)
                Container(
                  width: 80 + 48 * _pulseAnim.value,
                  height: 80 + 48 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(
                        alpha: 0.15 * (1 - _pulseAnim.value)),
                  ),
                ),
              // Inner pulse ring
              if (widget.isListening)
                Container(
                  width: 80 + 24 * _pulseAnim.value,
                  height: 80 + 24 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(
                        alpha: 0.20 * (1 - _pulseAnim.value)),
                  ),
                ),
              // Main button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isListening ? 84 : 76,
                height: widget.isListening ? 84 : 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isRec
                        ? [Colors.redAccent.shade700, Colors.red.shade400]
                        : [primary, primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRec ? Colors.red : primary)
                          .withValues(alpha: 0.4),
                      blurRadius: isRec ? 24 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isContinuous
                      ? Icons.fiber_manual_record
                      : (widget.isListening ? Icons.stop_rounded : Icons.mic_rounded),
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
