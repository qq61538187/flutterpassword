import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/auto_lock_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/csv_parser.dart';
import '../widgets/slide_transition.dart';
import 'statistics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AuthService? _authService;
  AutoLockService? _autoLockService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在 didChangeDependencies 中获取 AuthService 引用
    if (_authService == null) {
      _authService = Provider.of<AuthService>(context, listen: false);
      _authService?.addListener(_onAuthStateChanged);
    }
    // 获取 AutoLockService 并临时禁用窗口失焦锁定
    if (_autoLockService == null) {
      _autoLockService = Provider.of<AutoLockService>(context, listen: false);
      _autoLockService?.temporarilyDisableFocusLossLock();
    }
  }

  @override
  void dispose() {
    // 恢复窗口失焦锁定
    _autoLockService?.restoreFocusLossLock();
    _autoLockService = null;
    // 使用保存的引用，而不是通过 context 查找
    _authService?.removeListener(_onAuthStateChanged);
    _authService = null;
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (_authService != null && !_authService!.isUnlocked) {
      // 如果应用已锁定，延迟关闭设置页面，让 AuthWrapper 先切换
      // 延迟一点时间，确保 AuthWrapper 已经切换到 UnlockScreen
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      // 触发重建，显示空白页面而不是黑屏
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// 显示密码验证对话框
  Future<String?> _showPasswordVerificationDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;
    bool isLoading = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: AppTheme.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              Color(0xFF0051D5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      const Expanded(
                        child: Text(
                          '验证主密码',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXL,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // 密码输入框
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: !isLoading,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: '主密码',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      hintText: '请输入主密码',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                        borderSide: BorderSide(
                          color: errorMessage != null
                              ? Colors.red
                              : AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                        borderSide: BorderSide(
                          color: errorMessage != null
                              ? Colors.red
                              : AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) async {
                      if (!isLoading) {
                        await _verifyPassword(
                          context,
                          setDialogState,
                          passwordController.text.trim(),
                          (loading) => isLoading = loading,
                          (error) => errorMessage = error,
                        );
                      }
                    },
                  ),

                  // 错误消息
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: AppTheme.fontSizeS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingL),

                  // 按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await _verifyPassword(
                                  context,
                                  setDialogState,
                                  passwordController.text.trim(),
                                  (loading) => isLoading = loading,
                                  (error) => errorMessage = error,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('验证'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 验证密码
  Future<void> _verifyPassword(
    BuildContext context,
    StateSetter setDialogState,
    String password,
    void Function(bool) setIsLoading,
    void Function(String?) setErrorMessage,
  ) async {
    if (password.isEmpty) {
      setDialogState(() {
        setErrorMessage('请输入密码');
      });
      return;
    }

    setDialogState(() {
      setIsLoading(true);
      setErrorMessage(null);
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // 使用 verifyPasswordOnly 方法，只验证密码不改变解锁状态
      final isValid = await authService.verifyPasswordOnly(password);

      if (isValid) {
        // 验证成功，关闭对话框并返回密码
        if (context.mounted) {
          Navigator.of(context).pop(password);
        }
      } else {
        setDialogState(() {
          setIsLoading(false);
          setErrorMessage('密码错误，请重试');
        });
      }
    } catch (e) {
      setDialogState(() {
        setIsLoading(false);
        setErrorMessage('验证失败: $e');
      });
    }
  }

  /// 显示修改主密码对话框
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final hintController = TextEditingController();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    String? errorMessage;
    bool isLoading = false;
    int currentStep = 0; // 0: 验证旧密码, 1: 设置新密码

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: AppTheme.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              Color(0xFF0051D5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          currentStep == 0 ? '验证当前密码' : '设置新密码',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeXL,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  if (currentStep == 0) ...[
                    // 步骤1: 验证当前密码
                    TextField(
                      controller: oldPasswordController,
                      obscureText: obscureOldPassword,
                      enabled: !isLoading,
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: '当前主密码',
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        hintText: '请输入当前主密码',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOldPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureOldPassword = !obscureOldPassword;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) async {
                        if (!isLoading) {
                          await _verifyOldPassword(
                            context,
                            setDialogState,
                            oldPasswordController.text.trim(),
                            (loading) => isLoading = loading,
                            (error) => errorMessage = error,
                            (step) => currentStep = step,
                          );
                        }
                      },
                    ),
                  ] else ...[
                    // 步骤2: 设置新密码
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      enabled: !isLoading,
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: '新主密码',
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        hintText: '至少8个字符',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      enabled: !isLoading,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: '确认新主密码',
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        hintText: '请再次输入新密码',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: BorderSide(
                            color: errorMessage != null
                                ? Colors.red
                                : AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) async {
                        if (!isLoading) {
                          await _changePassword(
                            context,
                            setDialogState,
                            oldPasswordController.text.trim(),
                            newPasswordController.text.trim(),
                            confirmPasswordController.text.trim(),
                            hintController.text.trim(),
                            (loading) => isLoading = loading,
                            (error) => errorMessage = error,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextField(
                      controller: hintController,
                      enabled: !isLoading,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: '密码提示（可选）',
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        hintText: '帮助您回忆密码的提示',
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 错误消息
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: AppTheme.fontSizeS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingL),

                  // 按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (currentStep == 0) {
                                  Navigator.of(context).pop();
                                } else {
                                  setDialogState(() {
                                    currentStep = 0;
                                    errorMessage = null;
                                    newPasswordController.clear();
                                    confirmPasswordController.clear();
                                    hintController.clear();
                                  });
                                }
                              },
                        child: Text(currentStep == 0 ? '取消' : '返回'),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (currentStep == 0) {
                                  await _verifyOldPassword(
                                    context,
                                    setDialogState,
                                    oldPasswordController.text.trim(),
                                    (loading) => isLoading = loading,
                                    (error) => errorMessage = error,
                                    (step) => currentStep = step,
                                  );
                                } else {
                                  await _changePassword(
                                    context,
                                    setDialogState,
                                    oldPasswordController.text.trim(),
                                    newPasswordController.text.trim(),
                                    confirmPasswordController.text.trim(),
                                    hintController.text.trim(),
                                    (loading) => isLoading = loading,
                                    (error) => errorMessage = error,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(currentStep == 0 ? '下一步' : '确认修改'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    hintController.dispose();
  }

  /// 验证旧密码
  Future<void> _verifyOldPassword(
    BuildContext context,
    StateSetter setDialogState,
    String password,
    void Function(bool) setIsLoading,
    void Function(String?) setErrorMessage,
    void Function(int) setCurrentStep,
  ) async {
    if (password.isEmpty) {
      setDialogState(() {
        setErrorMessage('请输入当前密码');
      });
      return;
    }

    setDialogState(() {
      setIsLoading(true);
      setErrorMessage(null);
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isValid = await authService.verifyPasswordOnly(password);

      if (isValid) {
        setDialogState(() {
          setIsLoading(false);
          setCurrentStep(1);
        });
      } else {
        setDialogState(() {
          setIsLoading(false);
          setErrorMessage('密码错误，请重试');
        });
      }
    } catch (e) {
      setDialogState(() {
        setIsLoading(false);
        setErrorMessage('验证失败: $e');
      });
    }
  }

  /// 执行修改密码操作
  Future<void> _changePassword(
    BuildContext context,
    StateSetter setDialogState,
    String oldPassword,
    String newPassword,
    String confirmPassword,
    String hint,
    void Function(bool) setIsLoading,
    void Function(String?) setErrorMessage,
  ) async {
    if (newPassword.isEmpty) {
      setDialogState(() {
        setErrorMessage('请输入新密码');
      });
      return;
    }

    if (newPassword.length < 8) {
      setDialogState(() {
        setErrorMessage('新密码长度至少为8个字符');
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setDialogState(() {
        setErrorMessage('两次输入的密码不一致');
      });
      return;
    }

    if (oldPassword == newPassword) {
      setDialogState(() {
        setErrorMessage('新密码不能与当前密码相同');
      });
      return;
    }

    setDialogState(() {
      setIsLoading(true);
      setErrorMessage(null);
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      // 1. 修改主密码哈希
      final success = await authService.changeMasterPassword(
        oldPassword,
        newPassword,
        hint: hint.isEmpty ? null : hint,
      );

      if (!success) {
        setDialogState(() {
          setIsLoading(false);
          setErrorMessage('修改密码失败，请重试');
        });
        return;
      }

      // 2. 重新加密所有密码项
      await storageService.reencryptAllItems(oldPassword, newPassword);

      // 3. 更新会话密码
      SessionService().setMasterPassword(newPassword);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('主密码修改成功，所有数据已重新加密'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setDialogState(() {
        setIsLoading(false);
        setErrorMessage('修改失败: $e');
      });
    }
  }

  Future<void> _exportPasswords(BuildContext context) async {
    try {
      // 先验证主密码
      final verifiedPassword = await _showPasswordVerificationDialog(context);
      if (verifiedPassword == null || !context.mounted) return;

      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final items = storageService.allItems;

      if (items.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有可导出的密码项'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出密码'),
          content: Text('确定要导出 ${items.length} 个密码项吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('导出'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // 获取 CategoryService 以获取分类颜色
      final categoryService =
          Provider.of<CategoryService>(context, listen: false);

      // 转换为 CSV 格式
      final csvContent = CsvParser.toCsv(items, categoryService);

      // 使用文件选择器选择保存位置
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择导出位置',
        fileName:
            'flutterpassword_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result);
        // 使用 UTF-8 编码写入文件（包含 BOM）
        await file.writeAsString(csvContent, encoding: utf8);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功！共导出 ${items.length} 个密码项'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importPasswords(BuildContext context) async {
    // 保存 scaffoldMessenger 引用，用于错误处理
    final scaffoldMessengerForError = ScaffoldMessenger.of(context);
    try {
      // 先验证主密码
      final verifiedPassword = await _showPasswordVerificationDialog(context);
      if (verifiedPassword == null || !context.mounted) return;

      final storageService =
          Provider.of<StorageService>(context, listen: false);
      // 使用验证后的密码
      final masterPassword = verifiedPassword;

      // 确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入密码'),
          content: const Text('导入的密码项将添加到现有密码中，重复的密码项可能会被覆盖。确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('导入'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // 使用文件选择器
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name.toLowerCase();
        final fileContent = await file.readAsString();

        // 解析 CSV 文件
        if (!fileName.endsWith('.csv')) {
          if (!mounted) return;
          final scaffoldMessenger =
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('不支持的文件格式，请选择 CSV 文件'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 获取 CategoryService 以创建不存在的分类
        if (!mounted) return;
        final categoryService =
            // ignore: use_build_context_synchronously
            Provider.of<CategoryService>(context, listen: false);
        final scaffoldMessenger =
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context);

        ParseResult parseResult;
        try {
          parseResult = CsvParser.parseCsv(fileContent);
          if (parseResult.items.isEmpty) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('CSV 文件中没有有效的密码项'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        } catch (e) {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('CSV 解析失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 先处理分类创建
        int categoriesCreated = 0;
        for (var entry in parseResult.categoryColors.entries) {
          final categoryName = entry.key;
          final categoryColorValue = entry.value;

          // 检查分类是否存在
          if (!categoryService.categories.contains(categoryName)) {
            try {
              await categoryService.addCategory(
                categoryName,
                color: Color(categoryColorValue),
              );
              categoriesCreated++;
            } catch (e) {
              // 创建分类失败，跳过
            }
          } else {
            // 如果分类已存在，更新颜色（如果不同）
            final currentColor = categoryService.getCategoryColor(categoryName);
            if (currentColor.toARGB32() != categoryColorValue) {
              try {
                await categoryService.setCategoryColor(
                  categoryName,
                  Color(categoryColorValue),
                );
              } catch (e) {
                // 更新分类颜色失败，跳过
              }
            }
          }
        }

        // 导入所有项目（去重）
        int importedCount = 0;
        int skippedCount = 0;
        int failedCount = 0;

        for (var item in parseResult.items) {
          try {
            // 检查是否已存在相同的密码项（所有字段都相同）
            if (storageService.isDuplicate(item)) {
              skippedCount++;
              continue;
            }

            await storageService.saveItem(item, masterPassword);
            importedCount++;
          } catch (e) {
            failedCount++;
          }
        }

        if (!mounted) return;
        String message;
        List<String> parts = [];

        if (categoriesCreated > 0) {
          parts.add('创建分类: $categoriesCreated');
        }

        if (failedCount > 0) {
          parts.add('成功: $importedCount，跳过重复: $skippedCount，失败: $failedCount');
          message = '导入完成！${parts.join('，')}';
        } else if (skippedCount > 0) {
          parts.add('成功: $importedCount，跳过重复: $skippedCount');
          message = '导入完成！${parts.join('，')}';
        } else {
          parts.add('共导入 $importedCount 个项目');
          message = '导入成功！${parts.join('，')}';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerForError.showSnackBar(
        SnackBar(
          content: Text('导入失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResetDataDialog(BuildContext context) async {
    // 先验证主密码
    final verifiedPassword = await _showPasswordVerificationDialog(context);
    if (verifiedPassword == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '重置数据',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '此操作将删除所有数据，包括：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('• 所有密码项'),
            SizedBox(height: 4),
            Text('• 主密码'),
            SizedBox(height: 4),
            Text('• 所有分类'),
            SizedBox(height: 4),
            Text('• 所有设置'),
            SizedBox(height: 16),
            Text(
              '⚠️ 此操作不可恢复！',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '请确保已导出备份数据后再继续。',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _resetAllData(context);
    }
  }

  Future<void> _resetAllData(BuildContext context) async {
    try {
      // 显示加载提示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 获取服务实例
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final sessionService = SessionService();

      // 1. 删除所有密码项（Hive 数据库）
      // 使用 StorageService 的方法来清空数据，确保使用同一个 box 实例
      try {
        await storageService.clearAllData();
      } catch (e) {
        // 清除密码数据库失败
      }

      // 2. 删除 SharedPreferences 中的所有数据
      final prefs = await SharedPreferences.getInstance();

      // 删除主密码哈希
      await prefs.remove('master_password_hash');

      // 删除分类数据
      await prefs.remove('password_categories');
      await prefs.remove('category_colors');

      // 删除自动锁定设置
      await prefs.remove('auto_lock_timeout_minutes');
      await prefs.remove('lock_on_focus_loss_delay_seconds');

      // 3. 清除内存中的数据
      // 注意：storageService.clearAllData() 已经在步骤1中调用，这里不需要再次调用

      // 清除会话密码
      sessionService.clearMasterPassword();

      // 清除主密码哈希（内存和 SharedPreferences 都已清除）
      authService.clearMasterPassword();

      // 分类服务会在下次启动时自动从 SharedPreferences 加载
      // 由于我们已经清除了分类数据，下次加载时会使用默认分类

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('所有数据已成功删除'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 关闭设置页面，返回主界面（会显示解锁界面）
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }

      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重置数据失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showAutoLockSettings(BuildContext context) async {
    // 先验证主密码
    final verifiedPassword = await _showPasswordVerificationDialog(context);
    if (verifiedPassword == null || !context.mounted) return;

    final autoLockService =
        Provider.of<AutoLockService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => _AutoLockSettingsDialog(
          autoLockService: autoLockService,
          authService: authService,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 监听 AuthService，如果锁定则自动关闭
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // 如果应用已锁定，不渲染内容，等待关闭
        if (!authService.isUnlocked) {
          // 延迟关闭，确保 AuthWrapper 已经切换到 UnlockScreen
          // 保存 context 引用，避免异步使用警告
          final navigatorContext =
              context; // ignore: use_build_context_synchronously
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              final navigator = Navigator.of(navigatorContext);
              if (navigator.canPop()) {
                navigator.pop();
              }
            });
          });
          // 返回一个空白页面，避免显示黑屏
          return Scaffold(
            backgroundColor: AppTheme.lightBackground,
            body: Container(),
          );
        }

        return _buildSettingsContent(context);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXL,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('数据', Icons.storage_outlined),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.upload_outlined,
              iconColor: AppTheme.primaryBlue,
              title: '导出密码',
              subtitle: '导出所有密码项为 CSV 格式',
              onTap: () => _exportPasswords(context),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.download_outlined,
              iconColor: AppTheme.greenAccent,
              title: '导入密码',
              subtitle: '从 CSV 文件导入密码项',
              onTap: () => _importPasswords(context),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              title: '重置数据',
              subtitle: '删除所有数据（密码、分类、设置等）',
              onTap: () => _showResetDataDialog(context),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildSectionHeader('安全', Icons.lock_outline),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.lock_reset,
              iconColor: AppTheme.primaryBlue,
              title: '修改主密码',
              subtitle: '更改主密码并重新加密所有数据',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.timer_outlined,
              iconColor: AppTheme.orangeAccent,
              title: '自动锁定',
              subtitle: '设置自动锁定时间',
              onTap: () => _showAutoLockSettings(context),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildSectionHeader('分析', Icons.analytics_outlined),
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsCard(
              context,
              icon: Icons.analytics_outlined,
              iconColor: AppTheme.orangeAccent,
              title: '统计信息',
              subtitle: '查看密码统计和安全分析',
              onTap: () {
                Navigator.of(context).push(
                  SlidePageRoute(
                    page: const StatisticsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildSectionHeader('关于', Icons.info_outline),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'FlutterPassword 版本',
              subtitle: '1.0.0',
              onTap: () async {
                final url =
                    Uri.parse('https://github.com/qq61538187/flutterpassword');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  Color(0xFF0051D5),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeS,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeS,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppTheme.textSecondary,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: content,
      );
    }

    return content;
  }
}

class _AutoLockSettingsDialog extends StatefulWidget {
  final AutoLockService autoLockService;
  final AuthService authService;

  const _AutoLockSettingsDialog({
    required this.autoLockService,
    required this.authService,
  });

  @override
  State<_AutoLockSettingsDialog> createState() =>
      _AutoLockSettingsDialogState();
}

class _AutoLockSettingsDialogState extends State<_AutoLockSettingsDialog> {
  String selectedCategory = '自动锁定'; // 默认选中第一个分类

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          color: AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧分类列表
            Container(
              width: 180,
              decoration: const BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                  bottomLeft: Radius.circular(AppTheme.borderRadiusLarge),
                ),
              ),
              child: Column(
                children: [
                  // 标题
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: const Text(
                      '锁定设置',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeL,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // 分类列表
                  Expanded(
                    child: ListView(
                      children: [
                        _buildCategoryItemWidget(
                          '自动锁定',
                          Icons.timer_outlined,
                          selectedCategory == '自动锁定',
                          () {
                            setState(() {
                              selectedCategory = '自动锁定';
                            });
                          },
                        ),
                        _buildCategoryItemWidget(
                          '窗口失焦锁定',
                          Icons.visibility_outlined,
                          selectedCategory == '窗口失焦锁定',
                          () {
                            setState(() {
                              selectedCategory = '窗口失焦锁定';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 右侧选项列表
            Expanded(
              child: Column(
                children: [
                  // 标题
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          selectedCategory,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeL,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 选项列表
                  Expanded(
                    child: selectedCategory == '自动锁定'
                        ? _buildAutoLockOptions(
                            context,
                            widget.autoLockService,
                            widget.authService,
                          )
                        : _buildFocusLossOptions(
                            context,
                            widget.autoLockService,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItemWidget(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLockOptions(
    BuildContext context,
    AutoLockService autoLockService,
    AuthService authService,
  ) {
    final currentTimeout = autoLockService.lockTimeout;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildOptionItem(
          '5 分钟',
          currentTimeout.inMinutes == 5,
          () async {
            await autoLockService.setLockTimeout(
              const Duration(minutes: 5),
              authService: authService,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已设置为 5 分钟后自动锁定'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        _buildOptionItem(
          '10 分钟',
          currentTimeout.inMinutes == 10,
          () async {
            await autoLockService.setLockTimeout(
              const Duration(minutes: 10),
              authService: authService,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已设置为 10 分钟后自动锁定'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        _buildOptionItem(
          '30 分钟',
          currentTimeout.inMinutes == 30,
          () async {
            await autoLockService.setLockTimeout(
              const Duration(minutes: 30),
              authService: authService,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已设置为 30 分钟后自动锁定'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        _buildOptionItem(
          '永不',
          currentTimeout.inDays >= 365,
          () async {
            await autoLockService.setLockTimeout(
              const Duration(days: 365),
              authService: authService,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已关闭自动锁定'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFocusLossOptions(
    BuildContext context,
    AutoLockService autoLockService,
  ) {
    return Consumer<AutoLockService>(
      builder: (context, service, _) {
        final currentDelay = service.lockOnFocusLossDelay;

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _buildOptionItem(
              '不锁定',
              currentDelay == null,
              () async {
                await service.setLockOnFocusLossDelay(null);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已关闭窗口失焦锁定'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _buildOptionItem(
              '立即锁定',
              currentDelay == Duration.zero,
              () async {
                await service.setLockOnFocusLossDelay(Duration.zero);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已设置为窗口失焦时立即锁定'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _buildOptionItem(
              '30 秒后锁定',
              currentDelay?.inSeconds == 30,
              () async {
                await service.setLockOnFocusLossDelay(
                  const Duration(seconds: 30),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已设置为窗口失焦后 30 秒锁定'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _buildOptionItem(
              '1 分钟后锁定',
              currentDelay?.inMinutes == 1,
              () async {
                await service.setLockOnFocusLossDelay(
                  const Duration(minutes: 1),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已设置为窗口失焦后 1 分钟锁定'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            _buildOptionItem(
              '5 分钟后锁定',
              currentDelay?.inMinutes == 5,
              () async {
                await service.setLockOnFocusLossDelay(
                  const Duration(minutes: 5),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已设置为窗口失焦后 5 分钟锁定'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionItem(
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
