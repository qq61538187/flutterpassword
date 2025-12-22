import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/password_item.dart';
import 'encryption_service.dart';

class StorageService extends ChangeNotifier {
  static const String _boxName = 'passwords';
  static late Box<Map> _box;
  final EncryptionService _encryption = EncryptionService();

  final List<PasswordItem> _items = [];
  String _searchQuery = '';

  // 用于重置数据时清空列表
  void clearAllItems() {
    _items.clear();
    notifyListeners();
  }

  // 清空 Hive box 中的所有数据（用于重置数据功能）
  Future<void> clearAllData() async {
    await _box.clear();
    _items.clear();
    notifyListeners();
  }

  List<PasswordItem> get items => _filteredItems;
  List<PasswordItem> get allItems => _items;

  List<PasswordItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.username.toLowerCase().contains(query) ||
          (item.website?.toLowerCase().contains(query) ?? false) ||
          (item.notes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  static Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  Future<void> loadItems(String masterPassword) async {
    // 异步执行解密操作
    final List<PasswordItem> loadedItems = [];
    final encryptedData = _box.values.toList();
    
    // 直接执行解密
    for (var data in encryptedData) {
      try {
        final encryptedString = data['encrypted'] as String;
        final decrypted = _encryption.decrypt(encryptedString, masterPassword);
        final item = PasswordItem.fromJson(
          Map<String, dynamic>.from(decrypted),
        );
        loadedItems.add(item);
      } catch (e) {
        // 如果解密失败，跳过这个项目
      }
    }
    
    // 排序
    loadedItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    // 在主线程更新状态
    _items.clear();
    _items.addAll(loadedItems);
    notifyListeners();
  }

  Future<void> saveItem(PasswordItem item, String masterPassword) async {
    final json = item.toJson();
    final encrypted = _encryption.encrypt(json, masterPassword);
    
    await _box.put(item.id, {
      'encrypted': encrypted,
      'id': item.id,
    });

    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<String> getCategories() {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  List<PasswordItem> getFavoriteItems() {
    return _items.where((item) => item.isFavorite).toList();
  }

  Future<void> toggleFavorite(String id, String masterPassword) async {
    final item = _items.firstWhere((item) => item.id == id);
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    await saveItem(updatedItem, masterPassword);
  }

  Future<void> updateLastAccessed(String id, String masterPassword) async {
    final item = _items.firstWhere((item) => item.id == id);
    final updatedItem = item.copyWith(lastAccessed: DateTime.now());
    await saveItem(updatedItem, masterPassword);
  }

  List<PasswordItem> getRecentItems({int limit = 5}) {
    final recent = _items
        .where((item) => item.lastAccessed != null)
        .toList()
      ..sort((a, b) => (b.lastAccessed ?? DateTime(0))
          .compareTo(a.lastAccessed ?? DateTime(0)));
    return recent.take(limit).toList();
  }

  /// 检查密码项是否已存在（基于所有字段比较）
  bool isDuplicate(PasswordItem item) {
    return _items.any((existing) {
      return existing.title == item.title &&
          existing.username == item.username &&
          existing.password == item.password &&
          existing.website == item.website;
    });
  }

  /// 使用新主密码重新加密所有密码项
  /// 这个方法用于修改主密码时，需要将所有数据用新密码重新加密
  Future<void> reencryptAllItems(String oldPassword, String newPassword) async {
    // 1. 使用旧密码解密所有项
    final decryptedItems = <PasswordItem>[];
    final encryptedData = _box.values.toList();
    
    for (var data in encryptedData) {
      try {
        final encryptedString = data['encrypted'] as String;
        final decrypted = _encryption.decrypt(encryptedString, oldPassword);
        final item = PasswordItem.fromJson(
          Map<String, dynamic>.from(decrypted),
        );
        decryptedItems.add(item);
      } catch (e) {
        // 如果解密失败，跳过这个项目
      }
    }

    // 2. 使用新密码重新加密所有项
    for (var item in decryptedItems) {
      final json = item.toJson();
      final encrypted = _encryption.encrypt(json, newPassword);
      
      await _box.put(item.id, {
        'encrypted': encrypted,
        'id': item.id,
      });
    }

    // 3. 重新加载项到内存
    await loadItems(newPassword);
  }
}

