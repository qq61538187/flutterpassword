#!/bin/bash
# 强制重新编译图标的脚本

echo "🧹 清理构建缓存..."
flutter clean
rm -rf build/macos
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "📦 获取依赖..."
flutter pub get

echo "🔄 更新图标文件时间戳..."
touch macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png
touch macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json

echo "🗑️  清除系统图标缓存..."
killall Finder 2>/dev/null
killall Dock 2>/dev/null

echo "✅ 完成！现在请运行: flutter run -d macos"
echo "💡 提示: 如果图标仍未更新，请使用 Release 模式: flutter build macos --release"
