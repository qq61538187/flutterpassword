# Git 预提交钩子说明

项目已配置 Git 预提交钩子，在每次 `git commit` 时会自动运行 CI 检查。

## 功能

预提交钩子会自动执行以下检查：

1. ✅ **代码分析** - `flutter analyze --no-fatal-infos`
2. ✅ **代码格式** - `dart format --set-exit-if-changed .`
3. ✅ **完整 CI 检查** - 如果存在 `ci-check.sh`，会运行完整的检查流程

## 工作原理

当你运行 `git commit` 时：

1. Git 会自动执行 `.git/hooks/pre-commit` 脚本
2. 脚本会运行 `ci-check.sh`（如果存在）或基本检查
3. 如果检查通过，提交继续进行
4. 如果检查失败，提交会被阻止，你需要修复问题后重新提交

## 示例

### 正常提交（检查通过）

```bash
$ git commit -m "fix: 修复某个问题"
🔍 运行预提交检查...
🔍 开始本地 CI 检查...
...
✅ 预提交检查通过，允许提交
[main abc1234] fix: 修复某个问题
```

### 检查失败（提交被阻止）

```bash
$ git commit -m "添加新功能"
🔍 运行预提交检查...
🔍 开始本地 CI 检查...
...
❌ 代码分析失败，请修复问题后再提交
❌ 预提交检查失败，提交已被阻止
```

## 跳过预提交钩子（不推荐）

如果确实需要跳过检查（例如紧急修复），可以使用：

```bash
git commit --no-verify -m "紧急修复"
```

⚠️ **注意**：只有在紧急情况下才应该跳过检查。

## 手动运行检查

你也可以手动运行检查脚本：

```bash
./ci-check.sh
```

## 禁用预提交钩子

如果需要临时禁用预提交钩子：

```bash
# 重命名钩子文件
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# 重新启用
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 为新克隆配置钩子

如果你克隆了项目，需要手动设置钩子：

```bash
# 复制钩子文件
cp .git/hooks/pre-commit.example .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

或者直接运行：

```bash
chmod +x .git/hooks/pre-commit
```

## 故障排除

### 钩子没有执行

1. 检查文件权限：`chmod +x .git/hooks/pre-commit`
2. 检查文件是否存在：`ls -la .git/hooks/pre-commit`
3. 检查 Git 配置：`git config core.hooksPath`

### 检查太慢

如果检查太慢，可以修改 `ci-check.sh`，只运行关键检查：

```bash
# 只运行代码分析和格式检查
flutter analyze --no-fatal-infos
dart format --set-exit-if-changed .
```
