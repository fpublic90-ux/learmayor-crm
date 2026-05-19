import 'package:flutter/material.dart';
import '../../app/theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message = 'No records found at the moment.',
    this.icon = Icons.folder_open_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.08),
                        AppTheme.primary.withOpacity(0.0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                  ),
                  child: Icon(
                    icon, 
                    size: 48, 
                    color: AppTheme.primary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMid,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
