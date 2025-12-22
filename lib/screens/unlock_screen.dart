import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/particle_background.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _hintController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordHint; // 存储密码提示

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPasswordHint();
  }

  /// 加载密码提示
  Future<void> _loadPasswordHint() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.hasMasterPassword()) {
      final hint = await authService.getMasterPasswordHint();
      if (mounted) {
        setState(() {
          _passwordHint = hint;
        });
      }
    }
  }


  Future<void> _handleUnlock() async {
    // 立即更新 UI 状态，让用户看到反馈
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final isFirstTime = !authService.hasMasterPassword();

      if (isFirstTime) {
        // 首次设置主密码
        final password = _passwordController.text.trim();
        final confirmPassword = _confirmPasswordController.text.trim();

        if (password.isEmpty) {
          setState(() {
            _errorMessage = '请输入密码';
            _isLoading = false;
          });
          return;
        }

        if (password.length < 8) {
          setState(() {
            _errorMessage = '密码长度至少需要 8 个字符';
            _isLoading = false;
          });
          return;
        }

        if (password != confirmPassword) {
          setState(() {
            _errorMessage = '两次输入的密码不一致';
            _isLoading = false;
          });
          return;
        }

        // 获取提示（可选）
        final hint = _hintController.text.trim();
        final success = await authService.setMasterPassword(
          password,
          hint: hint.isNotEmpty ? hint : null,
        );

        if (success) {
          // 设置会话密码
          SessionService().setMasterPassword(password);
          
          // 异步加载数据，不阻塞UI
          storageService.loadItems(password).catchError((e) {
            // 如果加载数据失败，重置解锁状态
            if (mounted) {
              authService.lock();
              setState(() {
                _errorMessage = '加载数据失败: $e';
                _isLoading = false;
              });
            }
          });
          // 不等待数据加载完成，立即返回，让界面响应
          // 成功后会通过 AuthService 的 notifyListeners 自动跳转到主界面
        } else {
          setState(() {
            _errorMessage = '设置主密码失败';
            _isLoading = false;
          });
        }
      } else {
        // 解锁
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          setState(() {
            _errorMessage = '请输入密码';
            _isLoading = false;
          });
          return;
        }

        // 验证密码（不改变解锁状态）
        // 在后台线程执行，不阻塞 UI
        final isValid = await authService.verifyPasswordOnly(password);
        
        if (!isValid) {
          if (mounted) {
            setState(() {
              _errorMessage = '密码错误，请重试';
              _isLoading = false;
            });
          }
          return;
        }

        // 密码验证成功，立即设置会话密码并解锁（不等待数据加载）
        SessionService().setMasterPassword(password);
        authService.unlockDirectly();
        
        // 异步加载数据，不阻塞UI和解锁流程
        // 数据会在后台加载，用户进入主界面时数据可能还在加载中
        storageService.loadItems(password).catchError((e) {
          // 如果加载数据失败，记录错误但不影响解锁
          // 用户可以在主界面重试
          if (mounted) {
            debugPrint('加载数据失败: $e');
          }
        });
        
        // 成功后会通过 AuthService 的 notifyListeners 自动跳转到主界面
      }
    } catch (e) {
      setState(() {
        _errorMessage = '发生错误: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // 如果还在加载，显示加载状态
        if (authService.isLoading) {
          return Scaffold(
            body: Container(
              color: AppTheme.darkBackground,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // 根据 AuthService 的状态确定是否是首次使用
        final isFirstTime = !authService.hasMasterPassword();
        
        // 如果不是首次使用，确保加载提示
        if (!isFirstTime && _passwordHint == null) {
          _loadPasswordHint();
        }

        return Scaffold(
          body: ParticleBackground(
            particleCount: 30,
            child: GradientBackground(
              colors: [
                AppTheme.darkBackground,
                const Color(0xFF0A0A0A),
                const Color(0xFF1A1A2E),
              ],
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 450,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with glow effect
                          RepaintBoundary(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    Color(0xFF0051D5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusLarge),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 标题
                          Text(
                            isFirstTime ? '欢迎使用 FlutterPassword' : '解锁保险库',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isFirstTime ? '请设置您的主密码' : '请输入您的主密码以访问您的密码',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // 密码输入框 with glassmorphism
                          if (!isFirstTime) ...[
                            RepaintBoundary(
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 60),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '主密码',
                                          labelStyle: const TextStyle(
                                              color: Colors.grey),
                                          floatingLabelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          hintText: '请输入密码',
                                          hintStyle: const TextStyle(
                                              color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                          isDense: false,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.borderRadiusMedium),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // 显示/隐藏密码图标
                                              IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              // 如果有提示，显示感叹号图标（在眼睛图标后面）
                                              if (_passwordHint != null && _passwordHint!.isNotEmpty)
                                                Tooltip(
                                                  message: _passwordHint!,
                                                  waitDuration: const Duration(milliseconds: 300),
                                                  textStyle: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: AppTheme.fontSizeS,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.85),
                                                    borderRadius: BorderRadius.circular(
                                                        AppTheme.borderRadiusSmall),
                                                  ),
                                                  child: MouseRegion(
                                                    cursor: SystemMouseCursors.click,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.info_outline_rounded,
                                                        color: AppTheme.primaryBlue,
                                                        size: 22,
                                                      ),
                                                      onPressed: () {
                                                        // 点击也可以显示提示（可选）
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        onSubmitted: (_) => _handleUnlock(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (isFirstTime) ...[
                            // 首次设置：密码输入框
                            RepaintBoundary(
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 60),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '主密码',
                                          labelStyle: const TextStyle(
                                              color: Colors.grey),
                                          floatingLabelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          hintText: '请输入密码',
                                          hintStyle: const TextStyle(
                                              color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                          isDense: false,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.borderRadiusMedium),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        onSubmitted: (_) {
                                          // 首次设置时，按回车键聚焦到确认密码框
                                          FocusScope.of(context).nextFocus();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            RepaintBoundary(
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 60),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadiusMedium),
                                      ),
                                      child: TextField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirm,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '确认密码',
                                          labelStyle: const TextStyle(
                                              color: Colors.grey),
                                          floatingLabelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          hintText: '请再次输入密码',
                                          hintStyle: const TextStyle(
                                              color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                          isDense: false,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.borderRadiusMedium),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirm =
                                                    !_obscureConfirm;
                                              });
                                            },
                                          ),
                                        ),
                                        onSubmitted: (_) => _handleUnlock(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            // 提示输入框（首次设置时）- 与密码输入框样式统一
                            RepaintBoundary(
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 60),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  clipBehavior: Clip.hardEdge,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      child: TextField(
                                        controller: _hintController,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '密码提示（可选）',
                                          labelStyle: const TextStyle(
                                              color: Colors.grey),
                                          floatingLabelStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          hintText: '输入一个提示，帮助您回忆密码',
                                          hintStyle: const TextStyle(
                                              color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.1),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 20,
                                          ),
                                          isDense: false,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.borderRadiusMedium),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onSubmitted: (_) => _handleUnlock(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppTheme.spacingM),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusSmall),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: AppTheme.fontSizeS,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // 解锁按钮 with glow effect
                          RepaintBoundary(
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.primaryBlue.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusMedium),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleUnlock,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            isFirstTime ? '创建保险库' : '解锁',
                                            style: const TextStyle(
                                              fontSize: AppTheme.fontSizeM,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
