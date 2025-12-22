# 贡献指南

感谢你对 FlutterPassword 项目的关注！我们欢迎任何形式的贡献。

## 如何贡献

### 报告问题

如果你发现了 bug 或有功能建议，请先检查 [Issues](https://github.com/qq61538187/flutterpassword/issues) 中是否已有相关讨论。

提交 Issue 时，请提供以下信息：

- **操作系统与版本**：macOS / Windows 及其版本号
- **Flutter 版本**：运行 `flutter --version` 获取
- **问题描述**：清晰描述问题或建议
- **复现步骤**：如果是 bug，请提供详细的复现步骤
- **期望结果 vs 实际结果**：说明你期望的行为和实际发生的行为
- **相关截图/日志**：如有，请附上截图或错误日志

### 提交代码

#### 1. Fork 仓库

点击 GitHub 页面右上角的 "Fork" 按钮，将仓库 fork 到你的账户。

#### 2. 克隆仓库

```bash
git clone https://github.com/你的用户名/flutterpassword.git
cd flutterpassword
```

#### 3. 创建分支

```bash
git checkout -b feature/你的功能名称
# 或
git checkout -b fix/修复的问题描述
```

分支命名规范：
- `feature/` - 新功能
- `fix/` - Bug 修复
- `docs/` - 文档更新
- `refactor/` - 代码重构
- `test/` - 测试相关

#### 4. 开发环境设置

```bash
# 安装依赖
flutter pub get

# 生成代码（Hive 需要）
dart run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run -d macos  # macOS
# 或
flutter run -d windows  # Windows
```

#### 5. 开发规范

##### 代码风格

- 遵循 `analysis_options.yaml` 中的代码规范
- 使用 `flutter analyze` 检查代码
- 使用 `dart format .` 格式化代码
- 优先使用简体中文编写界面文案和注释

##### 提交信息

提交信息应清晰描述改动内容：

```bash
# 好的提交信息
git commit -m "feat: 添加密码强度检测功能"
git commit -m "fix: 修复 CSV 导入时的编码问题"
git commit -m "docs: 更新 README 中的安装说明"

# 不好的提交信息
git commit -m "更新"
git commit -m "修复bug"
```

提交信息格式：
- `feat:` - 新功能
- `fix:` - Bug 修复
- `docs:` - 文档更新
- `style:` - 代码格式（不影响功能）
- `refactor:` - 代码重构
- `test:` - 测试相关
- `chore:` - 构建/工具相关

##### 代码生成

如果修改了 Hive 模型，需要重新生成代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 6. 测试

在提交 PR 前，请确保：

```bash
# 运行代码分析
flutter analyze

# 运行测试
flutter test

# 检查代码格式
dart format --set-exit-if-changed .
```

#### 7. 提交 Pull Request

1. 推送你的分支到 GitHub：
   ```bash
   git push origin feature/你的功能名称
   ```

2. 在 GitHub 上创建 Pull Request：
   - 标题清晰描述改动内容
   - 在描述中说明：
     - 改动的目的
     - 如何测试
     - 相关 Issue（如有）

3. 等待代码审查：
   - 维护者会审查你的代码
   - 可能需要根据反馈进行修改
   - 请及时响应审查意见

## 开发指南

### 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
├── screens/                     # 界面页面
├── services/                    # 服务层（业务逻辑）
├── widgets/                     # 可复用组件
├── utils/                       # 工具类
└── theme/                       # 主题配置
```

### 添加新功能

1. **服务层**：在 `lib/services/` 中添加业务逻辑
2. **界面层**：在 `lib/screens/` 中添加页面
3. **组件层**：在 `lib/widgets/` 中添加可复用组件
4. **模型层**：在 `lib/models/` 中更新或添加数据模型

### 安全相关改动

由于这是一个密码管理器，涉及安全性的改动需要特别注意：

- 加密算法的改动需要详细说明和测试
- 涉及主密码处理的改动需要谨慎审查
- 数据存储格式的改动需要考虑向后兼容性

### 测试要求

- 新功能应包含相应的测试
- Bug 修复应包含回归测试
- 确保所有测试通过后再提交 PR

## 行为准则

- 尊重所有贡献者
- 接受建设性的批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

## 许可

通过提交代码，你同意你的贡献将在项目的 MIT License 下发布。

## 问题？

如果你有任何问题，可以：

- 在 [Issues](https://github.com/qq61538187/flutterpassword/issues) 中提问
- 查看 [README.md](README.md) 了解更多信息

再次感谢你的贡献！🎉

