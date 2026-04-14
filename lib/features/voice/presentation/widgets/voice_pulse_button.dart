import 'package:flutter/material.dart';
import '../../../../core/constants/theme.dart';

class VoicePulseButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const VoicePulseButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<VoicePulseButton> createState() => _VoicePulseButtonState();
}

class _VoicePulseButtonState extends State<VoicePulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoicePulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulsePainter(_controller.value, widget.isListening),
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AmarTheme.primary, AmarTheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  )
                ]
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double animationValue;
  final bool isListening;

  _PulsePainter(this.animationValue, this.isListening);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint1 = Paint()
      ..color = AmarTheme.secondaryFixed.withOpacity(0.2 * (1 - animationValue))
      ..style = PaintingStyle.fill;
      
    final paint2 = Paint()
      ..color = AmarTheme.secondaryFixed.withOpacity(0.1 * (1 - animationValue))
      ..style = PaintingStyle.fill;

    final maxRadius = size.width * 1.5;
    
    // Inner pulse
    canvas.drawCircle(center, (size.width / 2) + (animationValue * maxRadius * 0.5), paint1);
    
    // Outer pulse
    canvas.drawCircle(center, (size.width / 2) + (animationValue * maxRadius), paint2);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.isListening != isListening;
  }
}
