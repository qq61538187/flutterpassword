import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'password_list_screen.dart';
import 'password_detail_screen.dart';
import '../widgets/sidebar.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';
import '../services/auto_lock_service.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String? _selectedPasswordId;
  String _selectedCategory = '全部';
  String _selectedView = '全部项目';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAutoLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    
    final autoLockService = Provider.of<AutoLockService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // 只有在已解锁状态下才处理自动锁定
    if (!authService.isUnlocked) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.paused:
        if (autoLockService.lockOnFocusLossDelay != null) {
          autoLockService.handleFocusLoss(authService);
        }
        break;
      case AppLifecycleState.inactive:
        if (autoLockService.lockOnFocusLossDelay != null) {
          autoLockService.handleFocusLoss(authService);
        }
        break;
      case AppLifecycleState.resumed:
        autoLockService.handleFocusGain();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        if (autoLockService.lockOnFocusLossDelay != null) {
          autoLockService.handleFocusLoss(authService);
        }
        break;
    }
  }

  void _initAutoLock() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final autoLockService = Provider.of<AutoLockService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isUnlocked) {
        autoLockService.initialize(authService);
      }
    });
  }

  // 在用户交互时记录活动
  void _recordUserActivity() {
    final autoLockService = Provider.of<AutoLockService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isUnlocked) {
      autoLockService.recordActivity();
      autoLockService.resetIdleTimer(authService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!mounted) return;
        
        final autoLockService = Provider.of<AutoLockService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        
        if (!authService.isUnlocked) return;
        
        if (!hasFocus) {
          // 窗口失去焦点
          if (autoLockService.lockOnFocusLossDelay != null) {
            autoLockService.handleFocusLoss(authService);
          }
        } else {
          // 窗口获得焦点
          autoLockService.handleFocusGain();
        }
      },
      child: Listener(
        onPointerDown: (_) => _recordUserActivity(),
        onPointerMove: (_) => _recordUserActivity(),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (_) => _recordUserActivity(),
          child: Scaffold(
            backgroundColor: AppTheme.lightBackground,
            body: Row(
              children: [
                // 侧边栏
                Sidebar(
                  selectedView: _selectedView,
                  onViewChanged: (view) {
                    setState(() {
                      _selectedView = view;
                      _selectedPasswordId = null;
                      _selectedCategory = '全部';
                    });
                  },
                ),
                
                // 主内容区域
                Expanded(
                  child: Row(
                    children: [
                      // 密码列表
                      Container(
                        width: 360,
                        decoration: const BoxDecoration(
                          color: AppTheme.lightSurface,
                          border: Border(
                            right: BorderSide(color: AppTheme.borderColor, width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 4,
                              offset: Offset(1, 0),
                            ),
                          ],
                        ),
                        child: PasswordListScreen(
                          selectedPasswordId: _selectedPasswordId,
                          selectedCategory: _selectedCategory,
                          selectedView: _selectedView,
                          onPasswordSelected: (id) {
                            setState(() {
                              _selectedPasswordId = id;
                            });
                          },
                          onCategoryChanged: (category) {
                            setState(() {
                              _selectedCategory = category;
                              _selectedPasswordId = null;
                            });
                          },
                        ),
                      ),
                      
                      // 详情面板
                      Expanded(
                        child: _selectedPasswordId != null
                            ? PasswordDetailScreen(
                                passwordId: _selectedPasswordId!,
                                onDeleted: () {
                                  setState(() {
                                    _selectedPasswordId = null;
                                  });
                                },
                              )
                            : const EmptyDetailView(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyDetailView extends StatelessWidget {
  const EmptyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightBackground,
      child: const EmptyState(
        icon: Icons.lock_outline,
        title: '选择一个密码项查看详情',
        subtitle: '在左侧列表中选择一个密码项以查看详细信息',
      ),
    );
  }
}

