import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
}

class PasswordStrengthChecker {
  static PasswordStrength checkStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // 长度检查
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // 字符类型检查
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    // 复杂度检查
    if (password.length >= 8 && 
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 6) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.fair:
        return '一般';
      case PasswordStrength.good:
        return '良好';
      case PasswordStrength.strong:
        return '强';
    }
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.blue;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }
}

