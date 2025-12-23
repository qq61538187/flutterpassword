import '../models/password_item.dart';
import '../services/category_service.dart';
import 'package:uuid/uuid.dart';

/// 解析结果，包含密码项和分类信息
class ParseResult {
  final List<PasswordItem> items;
  final Map<String, int> categoryColors; // 分类名称 -> 颜色值

  ParseResult({
    required this.items,
    required this.categoryColors,
  });
}

class CsvParser {
  /// 将 PasswordItem 列表转换为 CSV 字符串
  /// CSV 格式：name,url,username,password,note,category,categoryColor
  /// 添加 UTF-8 BOM 以确保 Excel 等软件正确识别中文编码
  static String toCsv(
      List<PasswordItem> items, CategoryService categoryService) {
    final buffer = StringBuffer();

    // 添加 UTF-8 BOM，确保 Excel 等软件正确识别 UTF-8 编码
    buffer.write('\uFEFF');

    // 写入表头
    buffer.writeln('name,url,username,password,note,category,categoryColor');

    // 写入数据行
    for (var item in items) {
      final name = _escapeCsvField(item.title);
      final url = _escapeCsvField(item.website ?? '');
      final username = _escapeCsvField(item.username);
      final password = _escapeCsvField(item.password);
      final note = _escapeCsvField(item.notes ?? '');
      final category = _escapeCsvField(item.category);
      final categoryColor =
          categoryService.getCategoryColor(item.category).toARGB32().toString();

      buffer.writeln(
          '$name,$url,$username,$password,$note,$category,$categoryColor');
    }

    return buffer.toString();
  }

  /// 转义 CSV 字段（处理引号和逗号）
  static String _escapeCsvField(String field) {
    // 如果字段包含引号、逗号或换行符，需要用引号包裹并转义引号
    if (field.contains('"') || field.contains(',') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 解析 CSV 字符串并转换为 PasswordItem 列表
  /// CSV 格式：name,url,username,password,note,category,categoryColor
  static ParseResult parseCsv(String csvContent) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) {
      return ParseResult(items: [], categoryColors: {});
    }

    // 解析表头
    final headers = _parseCsvLine(lines[0]);
    if (headers.isEmpty) {
      return ParseResult(items: [], categoryColors: {});
    }

    // 查找列索引
    final nameIndex = headers.indexWhere((h) => h.toLowerCase() == 'name');
    final urlIndex = headers.indexWhere((h) => h.toLowerCase() == 'url');
    final usernameIndex =
        headers.indexWhere((h) => h.toLowerCase() == 'username');
    final passwordIndex =
        headers.indexWhere((h) => h.toLowerCase() == 'password');
    final noteIndex = headers.indexWhere((h) => h.toLowerCase() == 'note');
    final categoryIndex =
        headers.indexWhere((h) => h.toLowerCase() == 'category');
    final categoryColorIndex =
        headers.indexWhere((h) => h.toLowerCase() == 'categorycolor');

    if (nameIndex == -1 || usernameIndex == -1 || passwordIndex == -1) {
      throw const FormatException('CSV 文件缺少必需的列：name, username, password');
    }

    final items = <PasswordItem>[];
    final categoryColors = <String, int>{};
    const uuid = Uuid();

    // 解析数据行
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final values = _parseCsvLine(line);
        if (values.length <= nameIndex ||
            values.length <= usernameIndex ||
            values.length <= passwordIndex) {
          continue; // 跳过不完整的行
        }

        final name = values[nameIndex].trim();
        final username = values[usernameIndex].trim();
        final password = values[passwordIndex].trim();

        // 跳过空行或缺少必需字段的行
        if (name.isEmpty || username.isEmpty || password.isEmpty) {
          continue;
        }

        final url = urlIndex >= 0 && urlIndex < values.length
            ? values[urlIndex].trim()
            : '';
        final note = noteIndex >= 0 && noteIndex < values.length
            ? values[noteIndex].trim()
            : '';
        final category = categoryIndex >= 0 && categoryIndex < values.length
            ? values[categoryIndex].trim()
            : '登录'; // 如果没有类别，默认为"登录"

        // 解析分类颜色
        int? categoryColorValue;
        if (categoryColorIndex >= 0 && categoryColorIndex < values.length) {
          final colorStr = values[categoryColorIndex].trim();
          if (colorStr.isNotEmpty) {
            try {
              categoryColorValue = int.parse(colorStr);
            } catch (e) {
              // 如果解析失败，使用默认颜色
              categoryColorValue = null;
            }
          }
        }

        // 保存分类颜色信息（如果存在且分类名称不为空）
        if (category.isNotEmpty && categoryColorValue != null) {
          // 如果分类已存在，只更新颜色（保留第一个出现的颜色）
          if (!categoryColors.containsKey(category)) {
            categoryColors[category] = categoryColorValue;
          }
        }

        // 从 URL 中提取域名作为标题（如果没有 name）
        String title = name.isNotEmpty ? name : _extractDomainFromUrl(url);

        // 创建 PasswordItem
        final item = PasswordItem(
          id: uuid.v4(),
          title: title,
          username: username,
          password: password,
          website: url.isNotEmpty ? url : null,
          notes: note.isNotEmpty ? note : null,
          category: category.isNotEmpty ? category : '登录',
        );

        items.add(item);
      } catch (e) {
        // 跳过解析失败的行
        continue;
      }
    }

    return ParseResult(items: items, categoryColors: categoryColors);
  }

  /// 解析 CSV 行，处理引号和转义
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // 转义的双引号
          buffer.write('"');
          i++; // 跳过下一个引号
        } else {
          // 切换引号状态
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // 字段分隔符
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // 添加最后一个字段
    result.add(buffer.toString());

    return result;
  }

  /// 从 URL 中提取域名
  static String _extractDomainFromUrl(String url) {
    if (url.isEmpty) return '未命名';

    try {
      // 移除协议
      String domain = url;
      if (domain.contains('://')) {
        domain = domain.split('://')[1];
      }

      // 移除路径
      if (domain.contains('/')) {
        domain = domain.split('/')[0];
      }

      // 移除端口
      if (domain.contains(':')) {
        domain = domain.split(':')[0];
      }

      return domain.isNotEmpty ? domain : '未命名';
    } catch (e) {
      return '未命名';
    }
  }
}
