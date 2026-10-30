import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/contracts/safety_check_coordinator.dart';

class SafetyCheckDialog extends StatefulWidget {
  final SafetyCheckRequest request;
  final Function(SafetyCheckResponse) onResponse;
  final Function(int) onSnooze;

  const SafetyCheckDialog({
    super.key,
    required this.request,
    required this.onResponse,
    required this.onSnooze,
  });

  @override
  State<SafetyCheckDialog> createState() => _SafetyCheckDialogState();
}

class _SafetyCheckDialogState extends State<SafetyCheckDialog> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final remainingMs = widget.request.deadlineEpochMs - DateTime.now().millisecondsSinceEpoch;
    _remainingSeconds = (remainingMs / 1000).clamp(1, 120).round();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        widget.onResponse(SafetyCheckResponse.timeout);
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ResQTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ResQTheme.warningOrange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ResQTheme.warningOrange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: ResQTheme.warningOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Safety Check Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ResQTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ResQTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_remainingSeconds seconds remaining',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ResQTheme.warningOrange,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ResQTheme.safeGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _countdownTimer?.cancel();
                      widget.onResponse(SafetyCheckResponse.iAmSafe);
                    },
                    child: const Text('I AM SAFE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ResQTheme.sosRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _countdownTimer?.cancel();
                      widget.onResponse(SafetyCheckResponse.needHelp);
                    },
                    child: const Text('NEED HELP'),
                  ),
                ),
              ],
            ),
            if (widget.request.allowsSnooze) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  widget.onSnooze(300); // 5 min snooze
                },
                child: const Text('Remind me in 5 minutes (Snooze)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
