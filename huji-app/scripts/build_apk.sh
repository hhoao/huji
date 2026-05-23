#!/bin/bash

# Flutter APK/AAB 打包脚本
# 用法: ./scripts/build_apk.sh [选项]

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
BUILD_MODE="release"
BUILD_TYPE="apk"  # apk 或 appbundle
SPLIT_ABI=false
ANALYZE_SIZE=false
CLEAN_BUILD=false
TARGET_PLATFORM=""
VERSION_INFO=false

# 显示帮助信息
show_help() {
    echo "Flutter 打包脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -m, --mode MODE           构建模式: release (默认) 或 debug"
    echo "  -t, --type TYPE           构建类型: apk (默认) 或 appbundle"
    echo "  -s, --split-abi           按架构分割 APK (仅 APK 模式)"
    echo "  -a, --analyze-size        构建后分析包大小"
    echo "  -c, --clean               构建前清理"
    echo "  -p, --platform PLATFORM   目标平台: android-arm, android-arm64, android-x64"
    echo "  -v, --version             显示版本信息"
    echo "  -h, --help                显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                                    # 构建 release APK"
    echo "  $0 -s                                 # 构建分架构 APK"
    echo "  $0 -t appbundle                      # 构建 AAB"
    echo "  $0 -s -a                             # 构建分架构 APK 并分析大小"
    echo "  $0 -c -s                             # 清理后构建分架构 APK"
    echo "  $0 -p android-arm64                  # 构建 arm64 架构 APK"
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -s|--split-abi)
            SPLIT_ABI=true
            shift
            ;;
        -a|--analyze-size)
            ANALYZE_SIZE=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -p|--platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        -v|--version)
            VERSION_INFO=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 验证构建模式
if [[ "$BUILD_MODE" != "release" && "$BUILD_MODE" != "debug" ]]; then
    echo -e "${RED}错误: 构建模式必须是 release 或 debug${NC}"
    exit 1
fi

# 验证构建类型
if [[ "$BUILD_TYPE" != "apk" && "$BUILD_TYPE" != "appbundle" ]]; then
    echo -e "${RED}错误: 构建类型必须是 apk 或 appbundle${NC}"
    exit 1
fi

# split-abi 只适用于 APK
if [[ "$SPLIT_ABI" == true && "$BUILD_TYPE" == "appbundle" ]]; then
    echo -e "${YELLOW}警告: split-abi 选项只适用于 APK，已忽略${NC}"
    SPLIT_ABI=false
fi

# 显示版本信息
if [[ "$VERSION_INFO" == true ]]; then
    echo -e "${BLUE}=== 版本信息 ===${NC}"
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    echo "应用版本: $VERSION"
    echo "Flutter 版本: $(flutter --version | head -1)"
    echo ""
fi

# 进入项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Flutter 打包脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "构建模式: ${GREEN}$BUILD_MODE${NC}"
echo -e "构建类型: ${GREEN}$BUILD_TYPE${NC}"
if [[ "$SPLIT_ABI" == true ]]; then
    echo -e "架构分割: ${GREEN}是${NC}"
fi
if [[ -n "$TARGET_PLATFORM" ]]; then
    echo -e "目标平台: ${GREEN}$TARGET_PLATFORM${NC}"
fi
echo ""

# 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: 未找到 Flutter 命令${NC}"
    exit 1
fi

# 清理构建
if [[ "$CLEAN_BUILD" == true ]]; then
    echo -e "${YELLOW}清理构建缓存...${NC}"
    flutter clean
    echo ""
fi

# 获取依赖
echo -e "${BLUE}获取依赖...${NC}"
flutter pub get
echo ""

# 构建命令
BUILD_CMD="flutter build $BUILD_TYPE --$BUILD_MODE"

# 添加 split-abi 选项
if [[ "$SPLIT_ABI" == true ]]; then
    BUILD_CMD="$BUILD_CMD --split-per-abi"
fi

# 添加目标平台
if [[ -n "$TARGET_PLATFORM" ]]; then
    BUILD_CMD="$BUILD_CMD --target-platform $TARGET_PLATFORM"
fi

# 添加大小分析
if [[ "$ANALYZE_SIZE" == true && "$BUILD_TYPE" == "apk" ]]; then
    if [[ -n "$TARGET_PLATFORM" ]]; then
        BUILD_CMD="$BUILD_CMD --analyze-size"
    else
        echo -e "${YELLOW}警告: 大小分析需要指定目标平台，已跳过${NC}"
    fi
fi

# 执行构建
echo -e "${BLUE}开始构建...${NC}"
echo -e "${YELLOW}执行命令: $BUILD_CMD${NC}"
echo ""

if eval "$BUILD_CMD"; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}构建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 显示输出文件位置
    if [[ "$BUILD_TYPE" == "apk" ]]; then
        if [[ "$SPLIT_ABI" == true ]]; then
            echo -e "${BLUE}生成的 APK 文件:${NC}"
            for apk in build/app/outputs/apk/$BUILD_MODE/app-*-release.apk; do
                if [[ -f "$apk" ]]; then
                    SIZE=$(du -h "$apk" | cut -f1)
                    echo -e "  ${GREEN}$apk${NC} (${SIZE})"
                fi
            done
        else
            APK_FILE="build/app/outputs/apk/$BUILD_MODE/app-release.apk"
            if [[ -f "$APK_FILE" ]]; then
                SIZE=$(du -h "$APK_FILE" | cut -f1)
                echo -e "${BLUE}生成的 APK 文件:${NC}"
                echo -e "  ${GREEN}$APK_FILE${NC} (${SIZE})"
            fi
        fi
    else
        AAB_FILE="build/app/outputs/bundle/${BUILD_MODE}Bundle/app-release.aab"
        if [[ -f "$AAB_FILE" ]]; then
            SIZE=$(du -h "$AAB_FILE" | cut -f1)
            echo -e "${BLUE}生成的 AAB 文件:${NC}"
            echo -e "  ${GREEN}$AAB_FILE${NC} (${SIZE})"
        fi
    fi
    
    echo ""
    
    # 如果启用了大小分析，运行分析脚本
    if [[ "$ANALYZE_SIZE" == true && "$BUILD_TYPE" == "apk" && -f "scripts/analyze_apk_size.sh" ]]; then
        echo -e "${BLUE}运行大小分析...${NC}"
        if [[ "$SPLIT_ABI" == true ]]; then
            for apk in build/app/outputs/apk/$BUILD_MODE/app-*-release.apk build/app/outputs/apk/$BUILD_MODE/app-*-debug.apk; do
                if [[ -f "$apk" ]]; then
                    echo ""
                    echo -e "${YELLOW}分析: $(basename $apk)${NC}"
                    export APK_PATH="$apk"
                    ./scripts/analyze_apk_size.sh
                fi
            done
        else
            export APK_PATH="build/app/outputs/apk/$BUILD_MODE/app-release.apk"
            if [[ "$BUILD_MODE" == "debug" ]]; then
                export APK_PATH="build/app/outputs/apk/$BUILD_MODE/app-debug.apk"
            fi
            ./scripts/analyze_apk_size.sh
        fi
    fi
    
    echo ""
    echo -e "${GREEN}完成！${NC}"
    
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}构建失败！${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi

