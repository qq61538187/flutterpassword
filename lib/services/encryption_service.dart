import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' hide Key;
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

/// 加密算法版本
enum EncryptionVersion {
  v2, // PBKDF2
}

class EncryptionService {
  // PBKDF2 参数
  // 注意：迭代次数需要在安全性和性能之间平衡
  // 6,000 次在桌面设备上通常能在 20-40ms 内完成，提供良好的安全性和用户体验
  // 这个值在安全性和性能之间取得了良好的平衡（适合桌面应用）
  // 注意：必须与 AuthService 中的迭代次数保持一致
  static const int _pbkdf2Iterations = 6000; // 迭代次数（优化性能）
  static const int _saltLength = 16; // 盐值长度（字节）
  static const int _keyLength = 32; // 密钥长度（字节）

  /// 加密数据
  /// 格式: version:algorithm:salt:iv:encrypted_data
  String encrypt(Map<String, dynamic> data, String password) {
    // 使用 PBKDF2 (v2)
    // 生成随机盐值
    final salt = _generateSalt();
    final saltBase64 = base64Encode(salt);
    
    // 使用盐值派生密钥
    final key = _deriveKeyPBKDF2WithSalt(password, salt);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    
    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    
    // 格式: v2:pbkdf2:salt_base64:iv_base64:encrypted_base64
    return 'v2:pbkdf2:$saltBase64:${iv.base64}:${encrypted.base64}';
  }

  /// 解密数据
  /// 格式: v2:pbkdf2:salt:iv:encrypted
  Map<String, dynamic> decrypt(String encryptedData, String password) {
    final parts = encryptedData.split(':');
    
    // 新版本格式: version:algorithm:salt:iv:encrypted (5部分)
    if (parts.length == 5) {
      final version = parts[0];
      final algorithm = parts[1];
      final saltBase64 = parts[2];
      final ivBase64 = parts[3];
      final encryptedBase64 = parts[4];
      
      if (version == 'v2' && algorithm == 'pbkdf2') {
        return _decryptV2(saltBase64, ivBase64, encryptedBase64, password);
      }
    }
    
    throw Exception('无效的加密数据格式: 部分数量=${parts.length}，期望格式: v2:pbkdf2:salt:iv:encrypted');
  }

  /// 解密 v2 版本（PBKDF2）
  Map<String, dynamic> _decryptV2(String saltBase64, String ivBase64, String encryptedBase64, String password) {
    final salt = base64Decode(saltBase64);
    final iv = IV.fromBase64(ivBase64);
    final encrypted = Encrypted.fromBase64(encryptedBase64);
    
    final key = _deriveKeyPBKDF2WithSalt(password, salt);
    final encrypter = Encrypter(AES(key));
    
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }


  /// 使用 PBKDF2 派生密钥（使用指定盐）
  Key _deriveKeyPBKDF2WithSalt(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);
    
    // 使用 pointycastle 实现 PBKDF2
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(
      Uint8List.fromList(salt),
      _pbkdf2Iterations,
      _keyLength,
    );
    pbkdf2.init(params);
    
    final key = pbkdf2.process(passwordBytes);
    
    // 确保密钥长度为 32 字节
    if (key.length < _keyLength) {
      final extended = Uint8List(_keyLength);
      extended.setRange(0, key.length, key);
      // 如果不够长，重复填充
      int offset = key.length;
      while (offset < _keyLength) {
        final remaining = _keyLength - offset;
        final copyLength = remaining > key.length ? key.length : remaining;
        extended.setRange(offset, offset + copyLength, key);
        offset += copyLength;
      }
      return Key(extended);
    }
    
    return Key(Uint8List.fromList(key.sublist(0, _keyLength)));
  }


  /// 生成随机盐值
  List<int> _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }
}

