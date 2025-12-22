import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();
  
  Timer? _clearTimer;
  static const Duration _defaultClearDelay = Duration(seconds: 30); // 默认 30 秒后清除
  
  // 复制到剪贴板并设置自动清除
  Future<void> copyToClipboard(String text, {Duration? clearDelay}) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    // 取消之前的清除定时器
    _clearTimer?.cancel();
    
    // 设置新的清除定时器
    final delay = clearDelay ?? _defaultClearDelay;
    _clearTimer = Timer(delay, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }
  
  // 立即清除剪贴板
  Future<void> clearClipboard() async {
    _clearTimer?.cancel();
    await Clipboard.setData(const ClipboardData(text: ''));
  }
  
  // 取消自动清除
  void cancelAutoClear() {
    _clearTimer?.cancel();
  }
  
  void dispose() {
    _clearTimer?.cancel();
  }
}

