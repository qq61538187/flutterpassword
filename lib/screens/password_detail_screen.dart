import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/clipboard_service.dart';
import '../models/password_item.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_transition.dart';
import 'password_edit_screen.dart';

class PasswordDetailScreen extends StatelessWidget {
  final String passwordId;
  final VoidCallback onDeleted;

  const PasswordDetailScreen({
    super.key,
    required this.passwordId,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storageService, _) {
        final item = storageService.allItems.firstWhere(
          (item) => item.id == passwordId,
          orElse: () => throw Exception('Password item not found'),
        );

        return RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.lightBackground,
                  AppTheme.lightBackground.withValues(alpha: 0.95),
                ],
              ),
            ),
          child: Column(
            children: [
              // 顶部工具栏 with glassmorphism
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightSurface,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXL,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                        Navigator.of(context).push(
                          SlidePageRoute(
                            page: PasswordEditScreen(
                              passwordItem: item,
                            ),
                          ),
                        );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit,
                            color: AppTheme.textTertiary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _deletePassword(context, item),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red[400],
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 详情内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图标和基本信息
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getColorFromString(item.title),
                                _getColorFromString(item.title).withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                            boxShadow: [
                              BoxShadow(
                                color: _getColorFromString(item.title).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              item.title.isNotEmpty
                                  ? item.title[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),

                      // 用户名
                      _DetailField(
                        label: '用户名',
                        value: item.username,
                        icon: Icons.person_outline,
                        onCopy: () => _copyToClipboard(context, item.username),
                      ),
                      const SizedBox(height: 16),

                      // 密码
                      _DetailField(
                        label: '密码',
                        value: item.password,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        onCopy: () => _copyToClipboard(context, item.password),
                      ),
                      const SizedBox(height: 16),

                      // 网站
                      if (item.website != null && item.website!.isNotEmpty) ...[
                        _DetailField(
                          label: '网站',
                          value: item.website!,
                          icon: Icons.language,
                          onCopy: () => _copyToClipboard(context, item.website!),
                          onOpen: () => _openWebsite(context, item.website!),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 类别
                      _DetailField(
                        label: '类别',
                        value: item.category,
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 16),


                      // 备注
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        Text(
                          '备注',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeS,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            item.notes!,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeM,
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                      ],

                      // 时间信息
                      Divider(color: AppTheme.borderColor),
                      const SizedBox(height: AppTheme.spacingM),
                      _InfoRow(
                        label: '创建时间',
                        value: _formatDateTime(item.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: '更新时间',
                        value: _formatDateTime(item.updatedAt),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await ClipboardService().copyToClipboard(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板（30 秒后自动清除）'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openWebsite(BuildContext context, String url) async {
    try {
      String urlToLaunch = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlToLaunch = 'https://$url';
      }
      final uri = Uri.parse(urlToLaunch);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开此网站'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开网站失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePassword(BuildContext context, PasswordItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${item.title}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.deleteItem(item.id);
      onDeleted();
    }
  }

  Color _getColorFromString(String str) {
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFFFF2D55),
    ];
    final index = str.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPassword;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  const _DetailField({
    required this.label,
    required this.value,
    required this.icon,
    this.isPassword = false,
    this.onCopy,
    this.onOpen,
  });

  @override
  State<_DetailField> createState() => _DetailFieldState();
}

class _DetailFieldState extends State<_DetailField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            fontSize: AppTheme.fontSizeXS,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: widget.isPassword
                    ? Text(
                        _obscured ? '•' * widget.value.length : widget.value,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeM,
                          fontFamily: widget.isPassword && !_obscured
                              ? 'monospace'
                              : null,
                          color: AppTheme.textPrimary,
                          letterSpacing: widget.isPassword && !_obscured ? 1.5 : 0,
                        ),
                      )
                    : Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeM,
                          color: AppTheme.textPrimary,
                        ),
                      ),
              ),
              if (widget.isPassword)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _obscured = !_obscured;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ),
              if (widget.onCopy != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onCopy,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.copy_outlined,
                        size: 18,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
              if (widget.onOpen != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onOpen,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeS,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeS,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

