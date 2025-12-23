#!/bin/bash
# 本地 CI 检查脚本 - 在提交前运行此脚本确保代码通过检查

set -e  # 遇到错误立即退出

echo "🔍 开始本地 CI 检查..."
echo ""

# 1. 获取依赖
echo "📦 步骤 1/5: 获取依赖..."
flutter pub get
echo "✅ 依赖获取完成"
echo ""

# 2. 生成代码
echo "🔧 步骤 2/5: 生成代码..."
if dart run build_runner build --delete-conflicting-outputs 2>/dev/null; then
    echo "✅ 代码生成完成"
else
    echo "⚠️  代码生成失败（如果项目不使用代码生成，可以忽略）"
fi
echo ""

# 3. 代码分析
echo "🔍 步骤 3/5: 代码分析..."
if flutter analyze --no-fatal-infos; then
    echo "✅ 代码分析通过"
else
    echo "❌ 代码分析失败，请修复问题后再提交"
    exit 1
fi
echo ""

# 4. 运行测试
echo "🧪 步骤 4/5: 运行测试..."
if flutter test; then
    echo "✅ 测试通过"
else
    echo "❌ 测试失败，请修复问题后再提交"
    exit 1
fi
echo ""

# 5. 检查代码格式
echo "📝 步骤 5/5: 检查代码格式..."
if dart format --set-exit-if-changed .; then
    echo "✅ 代码格式检查通过"
else
    echo "❌ 代码格式不符合要求，请运行 'dart format .' 格式化代码"
    exit 1
fi
echo ""

echo "🎉 所有检查通过！可以安全提交代码了。"
