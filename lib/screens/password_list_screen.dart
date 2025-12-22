import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../models/password_item.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/slide_transition.dart';
import 'password_edit_screen.dart';
import 'category_management_screen.dart';

class PasswordListScreen extends StatefulWidget {
  final String? selectedPasswordId;
  final String selectedCategory;
  final String selectedView;
  final Function(String) onPasswordSelected;
  final Function(String) onCategoryChanged;

  const PasswordListScreen({
    super.key,
    required this.selectedPasswordId,
    required this.selectedCategory,
    required this.selectedView,
    required this.onPasswordSelected,
    required this.onCategoryChanged,
  });

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<StorageService>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  List<PasswordItem> _getFilteredItems(List<PasswordItem> items) {
    List<PasswordItem> filtered = items;

    // 类别筛选
    if (widget.selectedCategory != '全部') {
      filtered = filtered.where((item) => item.category == widget.selectedCategory).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏和添加按钮
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.lightSurface,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeM,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索密码...',
                    hintStyle: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: AppTheme.fontSizeM,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppTheme.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              RepaintBoundary(
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showAddPasswordDialog();
                    },
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            '添加新密码',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeS,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ],
          ),
        ),

        // 类别筛选
        if (widget.selectedView == '全部项目')
          Consumer<CategoryService>(
            builder: (context, categoryService, _) {
              final categories = ['全部', ...categoryService.categories];
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightSurface,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == widget.selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AnimatedContainer(
                              duration: AppTheme.animationDuration,
                              height: 28,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue,
                                          AppTheme.primaryBlue.withValues(alpha: 0.8),
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : AppTheme.lightBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: AppTheme.borderColor.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onCategoryChanged(category),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      category,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        letterSpacing: 0.2,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // 管理按钮
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              SlidePageRoute(
                                page: const CategoryManagementScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.borderColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.settings,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

        // 密码列表
        Expanded(
          child: Consumer<StorageService>(
            builder: (context, storageService, _) {
              final items = _getFilteredItems(storageService.items);

              if (items.isEmpty) {
                String emptyMessage;
                IconData emptyIcon;
                String? emptySubtitle;
                
                if (_searchController.text.isNotEmpty) {
                  emptyMessage = '没有找到匹配的密码';
                  emptyIcon = Icons.search_off;
                  emptySubtitle = '尝试使用其他关键词搜索';
                } else if (widget.selectedCategory != '全部') {
                  emptyMessage = '此类别下没有密码项';
                  emptyIcon = Icons.category_outlined;
                  emptySubtitle = '尝试选择其他类别或添加新密码';
                } else {
                  emptyMessage = '还没有密码项';
                  emptyIcon = Icons.lock_outline;
                  emptySubtitle = '点击上方按钮添加第一个密码';
                }
                
                return EmptyState(
                  icon: emptyIcon,
                  title: emptyMessage,
                  subtitle: emptySubtitle,
                );
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.id == widget.selectedPasswordId;

                  return _PasswordListItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      widget.onPasswordSelected(item.id);
                    },
                    onEdit: () => _editPassword(item),
                    onDelete: () => _deletePassword(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddPasswordDialog() {
    Navigator.of(context).push(
      SlidePageRoute(
        page: const PasswordEditScreen(),
      ),
    );
  }

  void _editPassword(PasswordItem item) {
    Navigator.of(context).push(
      SlidePageRoute(
        page: PasswordEditScreen(passwordItem: item),
      ),
    );
  }

  Future<void> _deletePassword(PasswordItem item) async {
    if (!mounted) return;
    
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

    if (!mounted) return;
    
    if (confirmed == true) {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.deleteItem(item.id);
      if (widget.selectedPasswordId == item.id) {
        widget.onPasswordSelected('');
      }
    }
  }
}

class _PasswordListItem extends StatelessWidget {
  final PasswordItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PasswordListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getColorFromString(String str) {
    final colors = [
      AppTheme.primaryBlue,
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFFFF2D55),
      const Color(0xFF5AC8FA),
      const Color(0xFFFFCC00),
    ];
    final index = str.hashCode % colors.length;
    return colors[index.abs()];
  }

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
                  AppTheme.primaryBlue.withValues(alpha: 0.12),
                  AppTheme.primaryBlue.withValues(alpha: 0.06),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: isSelected
            ? Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                width: 1.5,
              )
            : Border.all(
                color: Colors.transparent,
                width: 1,
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // 图标
                RepaintBoundary(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getColorFromString(item.title),
                          _getColorFromString(item.title).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: _getColorFromString(item.title).withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.username,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeS,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // 操作菜单
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppTheme.textTertiary,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

