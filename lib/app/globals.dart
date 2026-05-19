import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class Globals {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  static void showSnackBar(String message, {bool isError = false}) {
    HapticFeedback.mediumImpact();
    // Small delay ensures the message appears after screen transitions complete
    Future.delayed(const Duration(milliseconds: 100), () {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(24),
          elevation: 0,
        ),
      );
    });
  }

  // High-Fidelity Feedback Orchestration
  static void successHaptic() => HapticFeedback.mediumImpact();
  static void errorHaptic() => HapticFeedback.heavyImpact();
  static void lightHaptic() => HapticFeedback.lightImpact();

  static void showPremiumSuccess(String message) {
    successHaptic();
    showSnackBar('✅ $message');
  }

  static void showPremiumError(String message) {
    errorHaptic();
    showSnackBar('❌ $message', isError: true);
  }
}

// Global Executive Error Boundary UI
class PremiumErrorWidget extends StatelessWidget {
  final String error;
  const PremiumErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                  child: const Icon(Icons.bug_report_rounded, color: Color(0xFFEF4444), size: 48),
                ),
                const SizedBox(height: 24),
                const Text('Stability Alert', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text('The executive interface encountered a structural anomaly. Our engineers have been notified.', 
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Safely Close Application'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
