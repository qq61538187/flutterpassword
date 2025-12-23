import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryInfo {
  final String name;
  final Color color;

  CategoryInfo({
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color.value, // ignore: deprecated_member_use - Required for JSON serialization
    };
  }

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      name: json['name'] ?? '',
      color: Color(json['color'] ?? 0xFF2196F3),
    );
  }
}

class CategoryService extends ChangeNotifier {
  static const String _categoriesKey = 'password_categories';
  static const String _categoryColorsKey = 'category_colors';
  
  // 默认类别和颜色
  static const Map<String, Color> _defaultCategories = {
    '登录': Color(0xFF2196F3),      // 蓝色
    '应用程序': Color(0xFF4CAF50),   // 绿色
    '其他': Color(0xFF9E9E9E),       // 灰色
  };

  List<String> _categories = _defaultCategories.keys.toList();
  Map<String, Color> _categoryColors = Map.from(_defaultCategories);

  List<String> get categories => List.unmodifiable(_categories);
  
  Color getCategoryColor(String category) {
    return _categoryColors[category] ?? _defaultCategories['其他']!;
  }

  CategoryService() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载类别列表
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final List<dynamic> decoded = json.decode(categoriesJson);
        _categories = decoded.cast<String>();
      }
      
      // 加载类别颜色
      final colorsJson = prefs.getString(_categoryColorsKey);
      if (colorsJson != null) {
        final Map<String, dynamic> decoded = json.decode(colorsJson);
        _categoryColors = decoded.map((key, value) => 
          MapEntry(key, Color(value as int)));
      } else {
        // 如果没有保存的颜色，使用默认颜色
        _categoryColors = Map.from(_defaultCategories);
        // 为已存在的类别设置默认颜色
        for (var category in _categories) {
          if (!_categoryColors.containsKey(category)) {
            _categoryColors[category] = _defaultCategories['其他']!;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      // 加载类别失败
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(_categories);
      await prefs.setString(_categoriesKey, categoriesJson);
      
      // 保存颜色
      final colorsMap = _categoryColors.map((key, value) => 
        MapEntry(key, value.value)); // ignore: deprecated_member_use - Required for JSON serialization
      final colorsJson = json.encode(colorsMap);
      await prefs.setString(_categoryColorsKey, colorsJson);
      
      notifyListeners();
    } catch (e) {
      // 保存类别失败
    }
  }

  Future<void> addCategory(String category, {Color? color}) async {
    if (category.trim().isEmpty) {
      throw Exception('类别名称不能为空');
    }
    
    final trimmedCategory = category.trim();
    if (_categories.contains(trimmedCategory)) {
      throw Exception('类别已存在');
    }

    _categories.add(trimmedCategory);
    _categoryColors[trimmedCategory] = color ?? _defaultCategories['其他']!;
    _categories.sort();
    await _saveCategories();
  }

  Future<void> updateCategory(String oldCategory, String newCategory, {Color? color}) async {
    if (newCategory.trim().isEmpty) {
      throw Exception('类别名称不能为空');
    }

    final trimmedNewCategory = newCategory.trim();
    final nameChanged = trimmedNewCategory != oldCategory;
    final colorChanged = color != null && color != _categoryColors[oldCategory];

    if (!nameChanged && !colorChanged) {
      return; // 没有变化
    }

    // 不允许修改默认分类的名称
    if (nameChanged && _defaultCategories.containsKey(oldCategory)) {
      throw Exception('不能修改默认分类的名称');
    }

    if (nameChanged && _categories.contains(trimmedNewCategory)) {
      throw Exception('类别已存在');
    }

    final index = _categories.indexOf(oldCategory);
    if (index == -1) {
      throw Exception('类别不存在');
    }

    if (nameChanged) {
      // 更新名称
      _categories[index] = trimmedNewCategory;
      // 迁移颜色
      final oldColor = _categoryColors[oldCategory];
      _categoryColors.remove(oldCategory);
      _categoryColors[trimmedNewCategory] = color ?? oldColor ?? _defaultCategories['其他'] ?? const Color(0xFF9E9E9E);
      _categories.sort();
    } else if (color != null) {
      // 只更新颜色（默认分类可以修改颜色）
      _categoryColors[oldCategory] = color;
    }
    
    await _saveCategories();
  }

  Future<void> setCategoryColor(String category, Color color) async {
    if (!_categories.contains(category)) {
      throw Exception('类别不存在');
    }
    
    _categoryColors[category] = color;
    await _saveCategories();
  }

  Future<void> deleteCategory(String category) async {
    if (!_categories.contains(category)) {
      throw Exception('类别不存在');
    }

    // 不允许删除默认类别
    if (_defaultCategories.containsKey(category)) {
      throw Exception('不能删除默认类别');
    }

    _categories.remove(category);
    _categoryColors.remove(category);
    await _saveCategories();
  }

  bool hasCategory(String category) {
    return _categories.contains(category);
  }

  /// 检查是否为默认分类
  static bool isDefaultCategory(String category) {
    return _defaultCategories.containsKey(category);
  }
}

