import '../models/password_item.dart';
import 'password_strength.dart';

class PasswordAnalyzer {
  /// 检测重复密码
  static Map<String, List<PasswordItem>> findDuplicatePasswords(
    List<PasswordItem> items,
  ) {
    final passwordMap = <String, List<PasswordItem>>{};
    
    for (var item in items) {
      if (!passwordMap.containsKey(item.password)) {
        passwordMap[item.password] = [];
      }
      passwordMap[item.password]!.add(item);
    }
    
    // 只返回重复的密码
    passwordMap.removeWhere((key, value) => value.length <= 1);
    return passwordMap;
  }

  /// 检测弱密码
  static List<PasswordItem> findWeakPasswords(List<PasswordItem> items) {
    return items.where((item) {
      final strength = PasswordStrengthChecker.checkStrength(item.password);
      return strength == PasswordStrength.weak;
    }).toList();
  }

  /// 检测重复用户名
  static Map<String, List<PasswordItem>> findDuplicateUsernames(
    List<PasswordItem> items,
  ) {
    final usernameMap = <String, List<PasswordItem>>{};
    
    for (var item in items) {
      final key = '${item.username}_${item.website ?? ""}';
      if (!usernameMap.containsKey(key)) {
        usernameMap[key] = [];
      }
      usernameMap[key]!.add(item);
    }
    
    // 只返回重复的用户名
    usernameMap.removeWhere((key, value) => value.length <= 1);
    return usernameMap;
  }

  /// 获取统计信息
  static Map<String, dynamic> getStatistics(List<PasswordItem> items) {
    final weakPasswords = findWeakPasswords(items);
    final duplicatePasswords = findDuplicatePasswords(items);
    final duplicateUsernames = findDuplicateUsernames(items);
    
    final categories = <String, int>{};
    for (var item in items) {
      categories[item.category] = (categories[item.category] ?? 0) + 1;
    }
    
    final strengthCount = <PasswordStrength, int>{
      PasswordStrength.weak: 0,
      PasswordStrength.fair: 0,
      PasswordStrength.good: 0,
      PasswordStrength.strong: 0,
    };
    
    for (var item in items) {
      final strength = PasswordStrengthChecker.checkStrength(item.password);
      strengthCount[strength] = (strengthCount[strength] ?? 0) + 1;
    }
    
    return {
      'total': items.length,
      'weakPasswords': weakPasswords.length,
      'duplicatePasswords': duplicatePasswords.length,
      'duplicateUsernames': duplicateUsernames.length,
      'categories': categories.length,
      'strengthCount': strengthCount,
      'withWebsite': items.where((item) => 
        item.website != null && item.website!.isNotEmpty
      ).length,
    };
  }
}

