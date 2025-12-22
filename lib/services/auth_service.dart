import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart';
import 'dart:convert';
import 'dart:math';

class AuthService extends ChangeNotifier {
  bool _isUnlocked = false;
  String? _masterPasswordHash;
  bool _isLoading = true;

  // PBKDF2 参数
  // 注意：迭代次数需要在安全性和性能之间平衡
  // 6,000 次在桌面设备上通常能在 20-40ms 内完成，提供良好的安全性和用户体验
  // 这个值在安全性和性能之间取得了良好的平衡（适合桌面应用）
  static const int _pbkdf2Iterations = 6000; // 迭代次数（优化性能）

  bool get isUnlocked => _isUnlocked;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadMasterPassword();
  }

  Future<void> _loadMasterPassword() async {
    final prefs = await SharedPreferences.getInstance();
    _masterPasswordHash = prefs.getString('master_password_hash');
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setMasterPassword(String password, {String? hint}) async {
    if (password.length < 8) {
      return false;
    }

    // 使用 PBKDF2 (v2) 生成密码哈希（在后台线程执行以避免阻塞 UI）
    final hash = await compute(_computePBKDF2Hash, {
      'password': password,
      'iterations': _pbkdf2Iterations,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('master_password_hash', hash);
    // 保存密码提示（如果提供）
    if (hint != null && hint.trim().isNotEmpty) {
      await prefs.setString('master_password_hint', hint.trim());
    } else {
      await prefs.remove('master_password_hint');
    }
    _masterPasswordHash = hash;
    _isUnlocked = true; // 设置密码后自动解锁
    notifyListeners();
    return true;
  }

  /// 获取主密码提示
  Future<String?> getMasterPasswordHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('master_password_hint');
  }

  Future<bool> unlock(String password) async {
    if (_masterPasswordHash == null) {
      // 首次使用，设置主密码
      return await setMasterPassword(password);
    }

    // 确保密码不为空
    if (password.isEmpty) {
      return false;
    }

    // 验证密码（仅支持 PBKDF2）
    if (await _verifyPassword(password, _masterPasswordHash!)) {
      _isUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    _isUnlocked = false;
    notifyListeners();
  }

  void clearMasterPassword() {
    _masterPasswordHash = null;
    _isUnlocked = false;
    notifyListeners();
  }

  bool hasMasterPassword() {
    return _masterPasswordHash != null;
  }

  /// 仅验证密码，不改变解锁状态（用于敏感操作前的验证）
  Future<bool> verifyPasswordOnly(String password) async {
    if (_masterPasswordHash == null) {
      return false;
    }

    // 确保密码不为空
    if (password.isEmpty) {
      return false;
    }

    // 验证密码（仅支持 PBKDF2），但不改变解锁状态
    return await _verifyPassword(password, _masterPasswordHash!);
  }

  /// 直接解锁（不验证密码，用于已验证密码后的快速解锁）
  void unlockDirectly() {
    if (!_isUnlocked) {
      _isUnlocked = true;
      // 立即通知监听者，触发界面跳转
      notifyListeners();
    }
  }

  /// 修改主密码
  /// 返回 true 表示成功，false 表示失败
  Future<bool> changeMasterPassword(String oldPassword, String newPassword,
      {String? hint}) async {
    if (newPassword.length < 8) {
      return false;
    }

    // 验证旧密码
    if (!await verifyPasswordOnly(oldPassword)) {
      return false;
    }

    // 使用 PBKDF2 (v2) 生成新密码哈希（在后台线程执行以避免阻塞 UI）
    final hash = await compute(_computePBKDF2Hash, {
      'password': newPassword,
      'iterations': _pbkdf2Iterations,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('master_password_hash', hash);
    // 保存密码提示（如果提供）
    if (hint != null && hint.trim().isNotEmpty) {
      await prefs.setString('master_password_hint', hint.trim());
    } else {
      await prefs.remove('master_password_hint');
    }
    _masterPasswordHash = hash;
    notifyListeners();
    return true;
  }

  /// 验证密码（仅支持 PBKDF2）
  Future<bool> _verifyPassword(String password, String storedHash) async {
    // 格式: v2:pbkdf2:salt_base64:hash_base64
    if (!storedHash.startsWith('v2:pbkdf2:')) {
      return false;
    }

    return await _verifyPasswordPBKDF2(password, storedHash);
  }

  /// 使用 PBKDF2 验证密码
  Future<bool> _verifyPasswordPBKDF2(String password, String storedHash) async {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 4 || parts[0] != 'v2' || parts[1] != 'pbkdf2') {
        return false;
      }

      final saltBase64 = parts[2];
      final hashBase64 = parts[3];

      final salt = base64Decode(saltBase64);
      final storedHashBytes = base64Decode(hashBase64);

      // 在后台线程执行 PBKDF2 计算
      final computedHash = await compute(_computePBKDF2WithSalt, {
        'password': password,
        'salt': salt,
        'iterations': _pbkdf2Iterations,
        'keyLength': storedHashBytes.length,
      });

      return _constantTimeEquals(computedHash, storedHashBytes);
    } catch (e) {
      return false;
    }
  }

  /// 常量时间比较（防止时序攻击）
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// 在 isolate 中计算 PBKDF2 哈希（用于生成新密码哈希）
/// 参数: {'password': String, 'iterations': int}
String _computePBKDF2Hash(Map<String, dynamic> params) {
  final password = params['password'] as String;
  final iterations = params['iterations'] as int;

  // 生成随机盐值
  final random = Random.secure();
  final salt = Uint8List(16);
  for (int i = 0; i < 16; i++) {
    salt[i] = random.nextInt(256);
  }
  final saltBase64 = base64Encode(salt);

  // 使用 PBKDF2 派生哈希
  final passwordBytes = utf8.encode(password);

  // 使用 pointycastle 实现 PBKDF2
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  final pbkdf2Params = Pbkdf2Parameters(
    salt,
    iterations,
    32, // 哈希长度（字节）
  );
  pbkdf2.init(pbkdf2Params);

  final hash = pbkdf2.process(passwordBytes);
  final hashBase64 = base64Encode(hash);

  return 'v2:pbkdf2:$saltBase64:$hashBase64';
}

/// 在 isolate 中计算 PBKDF2 哈希（使用指定盐值）
/// 参数: {'password': String, 'salt': List<int>, 'iterations': int, 'keyLength': int}
List<int> _computePBKDF2WithSalt(Map<String, dynamic> params) {
  final password = params['password'] as String;
  final salt = params['salt'] as List<int>;
  final iterations = params['iterations'] as int;
  final keyLength = params['keyLength'] as int;

  final passwordBytes = utf8.encode(password);

  // 使用 pointycastle 实现 PBKDF2
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  final pbkdf2Params = Pbkdf2Parameters(
    Uint8List.fromList(salt),
    iterations,
    keyLength,
  );
  pbkdf2.init(pbkdf2Params);

  return pbkdf2.process(passwordBytes);
}
