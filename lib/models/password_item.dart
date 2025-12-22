import 'package:uuid/uuid.dart';

class PasswordItem {
  String id;
  String title;
  String username;
  String password;
  String? website;
  String? notes;
  String category;
  DateTime createdAt;
  DateTime updatedAt;
  String? faviconUrl;
  bool isFavorite;
  DateTime? lastAccessed;

  PasswordItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    this.category = '登录',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.faviconUrl,
    this.isFavorite = false,
    this.lastAccessed,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PasswordItem copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? faviconUrl,
    bool? isFavorite,
    DateTime? lastAccessed,
  }) {
    return PasswordItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      faviconUrl: faviconUrl ?? this.faviconUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'faviconUrl': faviconUrl,
      'isFavorite': isFavorite,
      'lastAccessed': lastAccessed?.toIso8601String(),
    };
  }

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      website: json['website'],
      notes: json['notes'],
      category: json['category'] ?? '登录',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      faviconUrl: json['faviconUrl'],
      isFavorite: json['isFavorite'] ?? false,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : null,
    );
  }
}

