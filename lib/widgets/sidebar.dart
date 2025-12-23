import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_transition.dart';
import 'password_generator_dialog.dart';

class Sidebar extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;

  const Sidebar({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground.withValues(alpha: 0.98),
            const Color(0xFF1A1A1A),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: AppTheme.borderColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo 区域
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                RepaintBoundary(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          Color(0xFF0051D5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Text(
                  'FlutterPassword',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSizeL,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppTheme.darkSurface, height: 1),
          
          // 导航菜单
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storageService, _) {
                final totalCount = storageService.allItems.length;
                
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                  children: [
                _SidebarItem(
                  icon: Icons.home_outlined,
                  title: '全部项目',
                  count: totalCount,
                  isSelected: selectedView == '全部项目',
                  onTap: () => onViewChanged('全部项目'),
                ),
                    const SizedBox(height: AppTheme.spacingS),
                    _SidebarItem(
                      icon: Icons.vpn_key_outlined,
                      title: '密码生成器',
                      onTap: () {
                        _showPasswordGenerator(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          
          const Divider(color: AppTheme.darkSurface, height: 1),
          
          // 底部操作
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  title: '设置',
                  onTap: () {
                    Navigator.of(context).push(
                      SlidePageRoute(
                        page: const SettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SidebarItem(
                  icon: Icons.lock_outline,
                  title: '锁定',
                  onTap: () {
                    Provider.of<AuthService>(context, listen: false).lock();
                    SessionService().clearMasterPassword();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordGenerator(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PasswordGeneratorDialog(),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.count,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.animationDuration,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ]
            : null,
      ),
      child: RepaintBoundary(
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.grey[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : Colors.grey[300],
                      fontSize: AppTheme.fontSizeS,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

