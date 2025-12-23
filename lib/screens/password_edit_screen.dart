import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/password_item.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../widgets/password_generator_dialog.dart';
import '../services/session_service.dart';
import '../utils/password_strength.dart';
import '../theme/app_theme.dart';

class PasswordEditScreen extends StatefulWidget {
  final PasswordItem? passwordItem;

  const PasswordEditScreen({
    super.key,
    this.passwordItem,
  });

  @override
  State<PasswordEditScreen> createState() => _PasswordEditScreenState();
}

class _PasswordEditScreenState extends State<PasswordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '登录';
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.passwordItem != null) {
      _titleController.text = widget.passwordItem!.title;
      _usernameController.text = widget.passwordItem!.username;
      _passwordController.text = widget.passwordItem!.password;
      _websiteController.text = widget.passwordItem!.website ?? '';
      _notesController.text = widget.passwordItem!.notes ?? '';
      _selectedCategory = widget.passwordItem!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      // 获取主密码（这里简化处理，实际应该从安全的地方获取）
      // 注意：实际应用中应该更安全地处理主密码
      final masterPassword = await _getMasterPassword();

      final item = widget.passwordItem?.copyWith(
            title: _titleController.text,
            username: _usernameController.text,
            password: _passwordController.text,
            website: _websiteController.text.isEmpty
                ? null
                : _websiteController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            category: _selectedCategory,
          ) ??
          PasswordItem(
            id: const Uuid().v4(),
            title: _titleController.text,
            username: _usernameController.text,
            password: _passwordController.text,
            website: _websiteController.text.isEmpty
                ? null
                : _websiteController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            category: _selectedCategory,
          );

      await storageService.saveItem(item, masterPassword);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String> _getMasterPassword() async {
    final sessionService = SessionService();
    final password = sessionService.currentMasterPassword;
    if (password == null) {
      throw Exception('会话已过期，请重新解锁');
    }
    return password;
  }

  void _generatePassword() {
    showDialog(
      context: context,
      builder: (context) => const PasswordGeneratorDialog(),
    ).then((password) {
      if (password != null && password is String) {
        setState(() {
          _passwordController.text = password;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.lightSurface,
        title: Text(
          widget.passwordItem == null ? '添加密码' : '编辑密码',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : TextButton(
                    onPressed: _savePassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：Gmail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名/邮箱',
                  hintText: '例如：user@example.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 密码
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.autorenew),
                        onPressed: _generatePassword,
                        tooltip: '生成密码',
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // 更新密码强度显示
                },
              ),
              // 密码强度指示器
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PasswordStrengthIndicator(
                  password: _passwordController.text,
                ),
              ],
              const SizedBox(height: 16),

              // 网站
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: '网站 URL（可选）',
                  hintText: '例如：https://example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // 类别
              Consumer<CategoryService>(
                builder: (context, categoryService, _) {
                  final categories = categoryService.categories;
                  // 确保选中的类别在列表中，否则使用默认值
                  final initialCategory = categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : (categories.isNotEmpty ? categories.first : '登录');
                  if (initialCategory != _selectedCategory) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCategory = initialCategory;
                        });
                      }
                    });
                  }
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    // value 是受控组件的正确用法，用于保持状态同步
                    value:
                        _selectedCategory, // ignore: deprecated_member_use - value 是受控组件的正确用法
                    decoration: const InputDecoration(
                      labelText: '类别',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // 备注
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthChecker.checkStrength(password);
    final strengthText = PasswordStrengthChecker.getStrengthText(strength);
    final strengthColor = PasswordStrengthChecker.getStrengthColor(strength);

    return Row(
      children: [
        const Text(
          '密码强度: ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          strengthText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: strengthColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: _getStrengthValue(strength),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  double _getStrengthValue(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}
