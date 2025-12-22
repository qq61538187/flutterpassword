import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/password_generator.dart';
import '../theme/app_theme.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  String _generatedPassword = '';
  int _length = 20;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _isMemorable = false;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    setState(() {
      if (_isMemorable) {
        _generatedPassword = PasswordGenerator.generateMemorable(
          wordCount: 4,
          separator: '-',
        );
      } else {
        _generatedPassword = PasswordGenerator.generate(
          length: _length,
          includeUppercase: _includeUppercase,
          includeLowercase: _includeLowercase,
          includeNumbers: _includeNumbers,
          includeSymbols: _includeSymbols,
        );
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: RepaintBoundary(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightSurface,
                AppTheme.lightSurface.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          Color(0xFF0051D5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Text(
                  '密码生成器',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
            
            // 生成的密码 with enhanced style
            RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightBackground,
                      AppTheme.lightBackground.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                  Expanded(
                    child: SelectableText(
                      _generatedPassword,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeM,
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.copy,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            
            // 密码类型切换 with enhanced style
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppTheme.animationDuration,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: !_isMemorable
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  Color(0xFF0051D5),
                                ],
                              )
                            : null,
                        color: !_isMemorable ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        boxShadow: !_isMemorable
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_isMemorable) {
                            setState(() {
                              _isMemorable = false;
                            });
                            _generatePassword();
                          }
                        },
                        child: Center(
                          child: Text(
                            '随机密码',
                            style: TextStyle(
                              color: !_isMemorable ? Colors.white : AppTheme.textSecondary,
                              fontWeight: !_isMemorable ? FontWeight.w600 : FontWeight.normal,
                              fontSize: AppTheme.fontSizeS,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppTheme.animationDuration,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _isMemorable
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  Color(0xFF0051D5),
                                ],
                              )
                            : null,
                        color: _isMemorable ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        boxShadow: _isMemorable
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (!_isMemorable) {
                            setState(() {
                              _isMemorable = true;
                            });
                            _generatePassword();
                          }
                        },
                        child: Center(
                          child: Text(
                            '易记密码',
                            style: TextStyle(
                              color: _isMemorable ? Colors.white : AppTheme.textSecondary,
                              fontWeight: _isMemorable ? FontWeight.w600 : FontWeight.normal,
                              fontSize: AppTheme.fontSizeS,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 选项 with enhanced style
            if (!_isMemorable) ...[
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          '长度: $_length',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeS,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryBlue,
                        inactiveTrackColor: AppTheme.borderColor,
                        thumbColor: AppTheme.primaryBlue,
                        overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _length.toDouble(),
                        min: 8,
                        max: 64,
                        divisions: 56,
                        label: _length.toString(),
                        onChanged: (value) {
                          setState(() {
                            _length = value.toInt();
                          });
                          _generatePassword();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildCheckboxOption(
                      '包含大写字母',
                      Icons.text_fields,
                      _includeUppercase,
                      (value) {
                        setState(() {
                          _includeUppercase = value ?? true;
                        });
                        _generatePassword();
                      },
                    ),
                    const Divider(height: AppTheme.spacingM),
                    _buildCheckboxOption(
                      '包含小写字母',
                      Icons.text_fields_outlined,
                      _includeLowercase,
                      (value) {
                        setState(() {
                          _includeLowercase = value ?? true;
                        });
                        _generatePassword();
                      },
                    ),
                    const Divider(height: AppTheme.spacingM),
                    _buildCheckboxOption(
                      '包含数字',
                      Icons.numbers,
                      _includeNumbers,
                      (value) {
                        setState(() {
                          _includeNumbers = value ?? true;
                        });
                        _generatePassword();
                      },
                    ),
                    const Divider(height: AppTheme.spacingM),
                    _buildCheckboxOption(
                      '包含符号',
                      Icons.tag,
                      _includeSymbols,
                      (value) {
                        setState(() {
                          _includeSymbols = value ?? true;
                        });
                        _generatePassword();
                      },
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // 按钮 with enhanced style
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _generatePassword,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 18,
                                color: AppTheme.textPrimary,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                '重新生成',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeM,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  flex: 2,
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
                        onTap: () {
                          Navigator.of(context).pop(_generatedPassword);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              const Text(
                                '使用此密码',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: value
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: value ? AppTheme.primaryBlue : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeM,
                  color: AppTheme.textPrimary,
                  fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.animationDuration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: value
                    ? const LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          Color(0xFF0051D5),
                        ],
                      )
                    : null,
                color: value ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? AppTheme.primaryBlue
                      : AppTheme.borderColor,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

