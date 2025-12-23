import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'session_service.dart';

class AutoLockService extends ChangeNotifier {
  Timer? _idleTimer;
  Timer? _focusLossTimer;
  Duration _lockTimeout = const Duration(minutes: 10); // 默认 10 分钟
  Duration? _lockOnFocusLossDelay; // 窗口失焦时锁定延迟，null 表示不锁定
  bool _isInitialized = false;
  AuthService? _authService;
  bool _temporarilyDisabled = false; // 临时禁用窗口失焦锁定（例如在设置页面）

  Duration get lockTimeout => _lockTimeout;
  Duration? get lockOnFocusLossDelay => _lockOnFocusLossDelay;
  bool get lockOnFocusLoss => _lockOnFocusLossDelay != null; // 兼容性：返回是否有失焦锁定
  bool get isTemporarilyDisabled => _temporarilyDisabled;

  AutoLockService() {
    _loadSettings();
  }

  // 从本地存储加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final timeoutMinutes = prefs.getInt('auto_lock_timeout_minutes') ?? 10;
    _lockTimeout = Duration(minutes: timeoutMinutes);

    // 加载窗口失焦锁定延迟（秒），-1 表示不锁定，null 表示使用默认值（立即锁定）
    final focusLossDelaySeconds =
        prefs.getInt('lock_on_focus_loss_delay_seconds');
    if (focusLossDelaySeconds == null) {
      // 首次使用，默认立即锁定
      _lockOnFocusLossDelay = Duration.zero;
    } else if (focusLossDelaySeconds == -1) {
      _lockOnFocusLossDelay = null; // 不锁定
    } else {
      _lockOnFocusLossDelay = Duration(seconds: focusLossDelaySeconds);
    }
    notifyListeners();
  }

  // 保存设置到本地存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_lock_timeout_minutes', _lockTimeout.inMinutes);
    // 保存窗口失焦锁定延迟（秒），-1 表示不锁定
    await prefs.setInt(
      'lock_on_focus_loss_delay_seconds',
      _lockOnFocusLossDelay?.inSeconds ?? -1,
    );
  }

  // 初始化服务（需要传入 AuthService 实例）
  void initialize(AuthService authService) {
    if (_isInitialized) return;
    _isInitialized = true;
    _authService = authService;
    if (authService.isUnlocked) {
      recordActivity();
    }
  }

  // 设置锁定超时时间
  Future<void> setLockTimeout(Duration timeout,
      {AuthService? authService}) async {
    _lockTimeout = timeout;
    await _saveSettings();
    if (authService != null) {
      _authService = authService;
      _resetIdleTimer();
    }
    notifyListeners();
  }

  // 设置窗口失焦时锁定延迟
  Future<void> setLockOnFocusLossDelay(Duration? delay) async {
    _lockOnFocusLossDelay = delay;
    await _saveSettings();
    // 如果当前有失焦计时器，取消它
    _focusLossTimer?.cancel();
    _focusLossTimer = null;
    notifyListeners();
  }

  // 兼容性方法：设置是否在失焦时锁定（立即锁定）
  Future<void> setLockOnFocusLoss(bool enabled) async {
    await setLockOnFocusLossDelay(enabled ? Duration.zero : null);
  }

  // 记录用户活动
  void recordActivity() {
    _resetIdleTimer();
  }

  // 重置空闲计时器
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_lockTimeout.inDays >= 365) {
      // 如果设置为"永不"，不启动计时器
      return;
    }
    if (_authService != null && _authService!.isUnlocked) {
      _idleTimer = Timer(_lockTimeout, () {
        lockApp(_authService!);
      });
    }
  }

  // 公共方法：重置空闲计时器
  void resetIdleTimer(AuthService authService) {
    _authService = authService;
    _resetIdleTimer();
  }

  // 锁定应用（需要从外部传入 AuthService）
  void lockApp(AuthService authService) {
    authService.lock();
    SessionService().clearMasterPassword();
  }

  // 临时禁用窗口失焦锁定（例如在设置页面）
  void temporarilyDisableFocusLossLock() {
    _temporarilyDisabled = true;
    // 取消当前的失焦锁定计时器
    _focusLossTimer?.cancel();
    _focusLossTimer = null;
  }

  // 恢复窗口失焦锁定
  void restoreFocusLossLock() {
    _temporarilyDisabled = false;
  }

  // 处理窗口失焦
  void handleFocusLoss(AuthService authService) {
    // 如果临时禁用，跳过锁定
    if (_temporarilyDisabled) {
      return;
    }

    // 取消之前的失焦计时器
    _focusLossTimer?.cancel();

    if (_lockOnFocusLossDelay == null) {
      return;
    }

    if (_lockOnFocusLossDelay == Duration.zero) {
      // 立即锁定
      lockApp(authService);
    } else {
      // 延迟锁定
      _focusLossTimer = Timer(_lockOnFocusLossDelay!, () {
        lockApp(authService);
      });
    }
  }

  // 处理窗口获得焦点（取消失焦锁定计时器）
  void handleFocusGain() {
    // 取消失焦锁定计时器
    _focusLossTimer?.cancel();
    _focusLossTimer = null;
    recordActivity();
  }

  // 手动锁定
  void lock(AuthService authService) {
    lockApp(authService);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _focusLossTimer?.cancel();
    super.dispose();
  }
}
