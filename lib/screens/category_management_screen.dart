import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _categoryController = TextEditingController();
  Color _selectedColor = const Color(0xFF2196F3);

  // 预定义颜色列表
  final List<Color> _presetColors = [
    const Color(0xFF2196F3), // 蓝色
    const Color(0xFF4CAF50), // 绿色
    const Color(0xFFFF9800), // 橙色
    const Color(0xFF9E9E9E), // 灰色
    const Color(0xFFE91E63), // 粉色
    const Color(0xFF9C27B0), // 紫色
    const Color(0xFF00BCD4), // 青色
    const Color(0xFFFF5722), // 深橙色
    const Color(0xFF795548), // 棕色
    const Color(0xFF607D8B), // 蓝灰色
    const Color(0xFFF44336), // 红色
    const Color(0xFF009688), // 青绿色
  ];

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    _selectedColor = const Color(0xFF2196F3);
    _showCategoryDialog('添加类别', null);
  }

  void _showEditCategoryDialog(String category) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final isDefault = CategoryService.isDefaultCategory(category);
    _categoryController.text = category;
    _selectedColor = categoryService.getCategoryColor(category);
    _showCategoryDialog('编辑类别', category, isDefault: isDefault);
  }

  void _showCategoryDialog(String title, String? category, {bool isDefault = false}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _categoryController,
                    autofocus: !isDefault,
                    enabled: !isDefault,
                    decoration: InputDecoration(
                      labelText: '类别名称',
                      hintText: isDefault ? '默认分类不能修改名称' : '请输入类别名称',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _saveCategory(category),
                  ),
                  if (isDefault)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '默认分类只能修改颜色，不能修改名称',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    '选择颜色',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetColors.map((color) {
                      final isSelected = color.value == _selectedColor.value;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: isSelected ? 3 : 0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => _saveCategory(category),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveCategory(String? oldCategory) async {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final categoryName = _categoryController.text.trim();

    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('类别名称不能为空'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (oldCategory == null) {
        await categoryService.addCategory(categoryName, color: _selectedColor);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('类别添加成功'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await categoryService.updateCategory(
          oldCategory,
          categoryName,
          color: _selectedColor,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('类别更新成功'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('确定要删除类别 "$category" 吗？\n\n删除后，使用此类别的密码项将需要重新分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    try {
      await categoryService.deleteCategory(category);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('类别删除成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          '类别管理',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXL,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppTheme.lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CategoryService>(
        builder: (context, categoryService, _) {
          final categories = categoryService.categories;

          return Column(
            children: [
              // 添加按钮
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              Color(0xFF0051D5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
                            onTap: _showAddCategoryDialog,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: AppTheme.spacingS),
                                  Text(
                                    '添加类别',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeM,
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

              // 类别列表
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              '暂无类别',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeL,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            Text(
                              '点击上方按钮添加类别',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeM,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isDefault = CategoryService.isDefaultCategory(category);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
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
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppTheme.spacingM),
                                  child: Consumer<CategoryService>(
                                    builder: (context, categoryService, _) {
                                      final categoryColor = categoryService.getCategoryColor(category);
                                      return Row(
                                        children: [
                                          // 颜色指示器
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: categoryColor,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.borderColor.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.folder,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: AppTheme.spacingM),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      category,
                                                      style: TextStyle(
                                                        fontSize: AppTheme.fontSizeM,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                    if (isDefault) ...[
                                                      const SizedBox(width: AppTheme.spacingS),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '默认',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: AppTheme.primaryBlue,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // 编辑和删除按钮 - 默认分类不显示
                                          if (!isDefault) ...[
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              color: AppTheme.textSecondary,
                                              tooltip: '编辑',
                                              onPressed: () => _showEditCategoryDialog(category),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              color: Colors.red,
                                              tooltip: '删除',
                                              onPressed: () => _deleteCategory(category),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

