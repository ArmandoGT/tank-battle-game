/// ============================================================
/// Stage Intro View — "STAGE N" splash screen.
/// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/pixel_text.dart';

class StageIntroView extends StatefulWidget {
  final int stageNumber;
  final VoidCallback onComplete;

  const StageIntroView({
    super.key,
    required this.stageNumber,
    required this.onComplete,
  });

  @override
  State<StageIntroView> createState() => _StageIntroViewState();
}

class _StageIntroViewState extends State<StageIntroView> {
  @override
  void initState() {
    super.initState();
    // Auto-advance after 2.5 seconds.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF636363),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelText(
              text: 'STAGE',
              fontSize: 24,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            PixelText(
              text: '${widget.stageNumber}',
              fontSize: 32,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
