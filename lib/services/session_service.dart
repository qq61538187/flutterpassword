import 'package:flutter/foundation.dart';

/// 会话服务，用于临时存储当前会话的主密码
/// 注意：这是一个简化的实现，实际应用中应该使用更安全的方式
class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _currentMasterPassword;

  String? get currentMasterPassword => _currentMasterPassword;

  void setMasterPassword(String password) {
    _currentMasterPassword = password;
    notifyListeners();
  }

  void clearMasterPassword() {
    _currentMasterPassword = null;
    notifyListeners();
  }

  bool hasMasterPassword() {
    return _currentMasterPassword != null;
  }
}
