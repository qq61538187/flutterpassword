import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/password_analyzer.dart';
import '../utils/password_strength.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计信息'),
      ),
      body: Consumer<StorageService>(
        builder: (context, storageService, _) {
          final items = storageService.allItems;
          final stats = PasswordAnalyzer.getStatistics(items);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总览卡片
                _StatCard(
                  title: '总览',
                  children: [
                    _StatItem(
                      icon: Icons.lock_outline,
                      label: '总密码数',
                      value: '${stats['total']}',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      icon: Icons.category,
                      label: '类别数',
                      value: '${stats['categories']}',
                      color: Colors.green,
                    ),
                    _StatItem(
                      icon: Icons.language,
                      label: '有网站链接',
                      value: '${stats['withWebsite']}',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 密码强度分布
                _StatCard(
                  title: '密码强度分布',
                  children: [
                    _StrengthBar(
                      label: '强',
                      count: stats['strengthCount'][PasswordStrength.strong] ?? 0,
                      total: stats['total'] as int,
                      color: Colors.green,
                    ),
                    _StrengthBar(
                      label: '良好',
                      count: stats['strengthCount'][PasswordStrength.good] ?? 0,
                      total: stats['total'] as int,
                      color: Colors.blue,
                    ),
                    _StrengthBar(
                      label: '一般',
                      count: stats['strengthCount'][PasswordStrength.fair] ?? 0,
                      total: stats['total'] as int,
                      color: Colors.orange,
                    ),
                    _StrengthBar(
                      label: '弱',
                      count: stats['strengthCount'][PasswordStrength.weak] ?? 0,
                      total: stats['total'] as int,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 安全问题
                if (stats['weakPasswords'] as int > 0 ||
                    stats['duplicatePasswords'] as int > 0 ||
                    stats['duplicateUsernames'] as int > 0)
                  _StatCard(
                    title: '安全问题',
                    children: [
                      if (stats['weakPasswords'] as int > 0)
                        _WarningItem(
                          icon: Icons.warning,
                          label: '弱密码',
                          value: '${stats['weakPasswords']} 个',
                          color: Colors.red,
                          onTap: () {
                            _showWeakPasswords(context, storageService);
                          },
                        ),
                      if (stats['duplicatePasswords'] as int > 0)
                        _WarningItem(
                          icon: Icons.content_copy,
                          label: '重复密码',
                          value: '${stats['duplicatePasswords']} 组',
                          color: Colors.orange,
                          onTap: () {
                            _showDuplicatePasswords(context, storageService);
                          },
                        ),
                      if (stats['duplicateUsernames'] as int > 0)
                        _WarningItem(
                          icon: Icons.person_outline,
                          label: '重复用户名',
                          value: '${stats['duplicateUsernames']} 组',
                          color: Colors.orange,
                          onTap: () {
                            _showDuplicateUsernames(context, storageService);
                          },
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWeakPasswords(BuildContext context, StorageService storageService) {
    final weakPasswords = PasswordAnalyzer.findWeakPasswords(
      storageService.allItems,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('弱密码列表'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: weakPasswords.length,
            itemBuilder: (context, index) {
              final item = weakPasswords[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.username),
                trailing: const Icon(Icons.warning, color: Colors.red),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDuplicatePasswords(BuildContext context, StorageService storageService) {
    final duplicates = PasswordAnalyzer.findDuplicatePasswords(
      storageService.allItems,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重复密码'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: duplicates.length,
            itemBuilder: (context, index) {
              final entry = duplicates.entries.elementAt(index);
              return ExpansionTile(
                title: Text('${entry.value.length} 个密码项使用相同密码'),
                subtitle: Text('密码: ${entry.key.substring(0, entry.key.length > 10 ? 10 : entry.key.length)}...'),
                children: entry.value.map((item) => 
                  ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.username),
                  )
                ).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateUsernames(BuildContext context, StorageService storageService) {
    final duplicates = PasswordAnalyzer.findDuplicateUsernames(
      storageService.allItems,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重复用户名'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: duplicates.length,
            itemBuilder: (context, index) {
              final entry = duplicates.entries.elementAt(index);
              return ExpansionTile(
                title: Text('${entry.value.length} 个密码项使用相同用户名'),
                subtitle: Text('用户名: ${entry.value.first.username}'),
                children: entry.value.map((item) => 
                  ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.website ?? '无网站'),
                  )
                ).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Center(
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StrengthBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _WarningItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Center(
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: Icon(Icons.chevron_right, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

