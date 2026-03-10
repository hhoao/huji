#!/bin/bash

# Flutter APK 大小分析脚本

# 支持通过环境变量指定 APK 路径，否则使用默认路径
APK_PATH="${APK_PATH:-build/app/outputs/apk/release/app-release.apk}"
TEMP_DIR="/tmp/apk_analysis_$$"

# 如果是相对路径，转换为绝对路径
if [[ "$APK_PATH" != /* ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    APK_PATH="$PROJECT_DIR/$APK_PATH"
fi

if [ ! -f "$APK_PATH" ]; then
    echo "错误: 找不到 APK 文件: $APK_PATH"
    echo "请先运行: flutter build apk --release"
    exit 1
fi

echo "========================================="
echo "Flutter APK 大小分析"
echo "========================================="
echo ""

# 1. 基本信息
echo "1. APK 基本信息:"
echo "   文件路径: $APK_PATH"
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo "   文件大小: $APK_SIZE"
echo ""

# 2. 使用 Flutter 内置分析工具
echo "2. 使用 Flutter 内置分析工具:"
echo "   运行: flutter build apk --release --analyze-size"
echo ""

# 3. 解压并分析 APK 内容
echo "3. APK 内容分析:"
mkdir -p "$TEMP_DIR"
unzip -q "$APK_PATH" -d "$TEMP_DIR"

echo "   各目录大小:"
du -sh "$TEMP_DIR"/* | sort -hr | head -20
echo ""

echo "   最大的文件 (前20个):"
find "$TEMP_DIR" -type f -exec du -h {} + | sort -rh | head -20
echo ""

# 4. 分析 lib 目录 (包含 Flutter 引擎和 Dart 代码)
if [ -d "$TEMP_DIR/lib" ]; then
    echo "4. lib 目录分析 (包含原生库):"
    du -sh "$TEMP_DIR/lib"/* | sort -hr
    echo ""
    
    echo "   各架构的 libflutter.so 大小:"
    find "$TEMP_DIR/lib" -name "libflutter.so" -exec du -h {} \;
    echo ""
fi

# 5. 分析 assets 目录
if [ -d "$TEMP_DIR/assets" ]; then
    echo "5. assets 目录分析:"
    du -sh "$TEMP_DIR/assets"/* 2>/dev/null | sort -hr | head -10
    echo ""
fi

# 6. 分析 classes.dex 文件
if [ -f "$TEMP_DIR/classes.dex" ]; then
    echo "6. classes.dex 大小:"
    du -h "$TEMP_DIR/classes.dex"
    echo ""
fi

# 7. 分析 resources.arsc
if [ -f "$TEMP_DIR/resources.arsc" ]; then
    echo "7. resources.arsc 大小:"
    du -h "$TEMP_DIR/resources.arsc"
    echo ""
fi

# 8. 分析 META-INF
if [ -d "$TEMP_DIR/META-INF" ]; then
    echo "8. META-INF 目录大小:"
    du -sh "$TEMP_DIR/META-INF"
    echo ""
fi

# 9. 详细统计
echo "9. 详细文件类型统计:"
echo "   APK 文件类型分布:"
find "$TEMP_DIR" -type f -exec file {} \; | sed 's/.*: //' | sort | uniq -c | sort -rn | head -10
echo ""

# 10. 清理
rm -rf "$TEMP_DIR"

echo "========================================="
echo "分析完成！"
echo ""
echo "优化建议:"
echo "1. 检查是否有未使用的资源文件"
echo "2. 使用 split-per-abi 构建多个 APK: flutter build apk --split-per-abi"
echo "3. 启用代码混淆和资源压缩"
echo "4. 检查 assets 目录中的大文件"
echo "5. 考虑使用 App Bundle (AAB) 格式: flutter build appbundle"
echo "========================================="

