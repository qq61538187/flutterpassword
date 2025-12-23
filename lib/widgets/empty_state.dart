import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.primaryBlue.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 56,
                color: AppTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacingXL),
            action!,
          ],
        ],
      ),
    );
  }
}

