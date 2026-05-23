#!/bin/bash

# 检查 CHANGELOG.md 和 pubspec.yaml 是否一起修改
# 使用方法：./scripts/check_changelog_pubspec.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 检查 CHANGELOG.md 和 pubspec.yaml 更新...${NC}"

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ 错误: 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取暂存区的文件列表
STAGED_FILES=$(git diff --cached --name-only)

# 检查是否有代码文件被修改
HAS_CODE_CHANGES=false
HAS_CHANGELOG=false
HAS_PUBSPEC=false

# 检查代码文件
for file in $STAGED_FILES; do
    if [[ "$file" =~ \.(dart|kt|swift|java|xml|yaml|yml)$ ]] && [[ "$file" != "pubspec.yaml" ]]; then
        HAS_CODE_CHANGES=true
        break
    fi
done

# 检查 CHANGELOG.md
if echo "$STAGED_FILES" | grep -q "CHANGELOG.md"; then
    HAS_CHANGELOG=true
fi

# 检查 pubspec.yaml
if echo "$STAGED_FILES" | grep -q "pubspec.yaml"; then
    HAS_PUBSPEC=true
fi

echo "📋 暂存的文件:"
for file in $STAGED_FILES; do
    echo "  - $file"
done
echo ""

# 分析结果
if [ "$HAS_CODE_CHANGES" = true ]; then
    echo -e "${BLUE}🔍 检测到代码文件修改${NC}"
    
    if [ "$HAS_CHANGELOG" = false ]; then
        echo -e "${YELLOW}⚠️  警告: 检测到代码修改，但 CHANGELOG.md 未更新${NC}"
        echo "   建议在提交前更新 CHANGELOG.md 文件"
        echo "   格式: ## [版本号] - (日期)"
    else
        echo -e "${GREEN}✅ CHANGELOG.md 已更新${NC}"
    fi
    
    if [ "$HAS_PUBSPEC" = false ]; then
        echo -e "${YELLOW}⚠️  警告: 检测到代码修改，但 pubspec.yaml 未更新${NC}"
        echo "   如果这是新功能或修复，请检查是否需要更新版本号"
        echo "   当前版本: $(grep '^version:' pubspec.yaml | sed 's/version: //')"
    else
        echo -e "${GREEN}✅ pubspec.yaml 已更新${NC}"
    fi
    
    # 检查 CHANGELOG.md 格式
    if [ "$HAS_CHANGELOG" = true ]; then
        echo ""
        echo -e "${BLUE}📝 检查 CHANGELOG.md 格式...${NC}"
        
        # 获取 CHANGELOG.md 的修改内容
        CHANGELOG_DIFF=$(git diff --cached CHANGELOG.md)
        
        # 检查是否包含版本标题
        if echo "$CHANGELOG_DIFF" | grep -q "^+## \[.*\] - (.*)"; then
            echo -e "${GREEN}✅ 版本标题格式正确${NC}"
        else
            echo -e "${RED}❌ 版本标题格式错误${NC}"
            echo "   正确格式: ## [版本号] - (日期)"
            echo "   示例: ## [1.2.0] - (2025-01-15)"
        fi
        
        # 检查是否包含变更内容
        if echo "$CHANGELOG_DIFF" | grep -q "^+[*-] "; then
            echo -e "${GREEN}✅ 包含变更内容${NC}"
        else
            echo -e "${YELLOW}⚠️  警告: 未检测到变更内容${NC}"
            echo "   请添加具体的变更描述"
        fi
    fi
    
    # 检查 pubspec.yaml 版本更新
    if [ "$HAS_PUBSPEC" = true ]; then
        echo ""
        echo -e "${BLUE}📦 检查 pubspec.yaml 版本更新...${NC}"
        
        # 获取版本号变化
        VERSION_DIFF=$(git diff --cached pubspec.yaml | grep "^[+-]version:")
        if [ -n "$VERSION_DIFF" ]; then
            echo -e "${GREEN}✅ 版本号已更新${NC}"
            echo "$VERSION_DIFF"
        else
            echo -e "${YELLOW}⚠️  警告: 版本号未更新${NC}"
            echo "   如果这是新功能或修复，建议更新版本号"
        fi
    fi
    
    # 检查版本号一致性
    if [ "$HAS_CHANGELOG" = true ] && [ "$HAS_PUBSPEC" = true ]; then
        echo ""
        echo -e "${BLUE}🔗 检查版本号一致性...${NC}"
        
        # 从 CHANGELOG.md 提取版本号
        CHANGELOG_VERSION=$(git diff --cached CHANGELOG.md | grep "^+## \[.*\]" | head -1 | sed 's/^+## \[\([^]]*\)\].*/\1/')
        
        # 从 pubspec.yaml 提取版本号
        PUBSPEC_VERSION=$(git diff --cached pubspec.yaml | grep "^+version:" | sed 's/^+version: //')
        
        if [ -n "$CHANGELOG_VERSION" ] && [ -n "$PUBSPEC_VERSION" ]; then
            if [ "$CHANGELOG_VERSION" = "$PUBSPEC_VERSION" ]; then
                echo -e "${GREEN}✅ 版本号一致: $CHANGELOG_VERSION${NC}"
            else
                echo -e "${RED}❌ 版本号不一致${NC}"
                echo "   CHANGELOG.md: $CHANGELOG_VERSION"
                echo "   pubspec.yaml: $PUBSPEC_VERSION"
            fi
        fi
    fi
    
else
    echo -e "${GREEN}✅ 未检测到代码文件修改${NC}"
    echo "   跳过 CHANGELOG.md 和 pubspec.yaml 检查"
fi

echo ""
echo "=================================="

# 总结
if [ "$HAS_CODE_CHANGES" = true ]; then
    if [ "$HAS_CHANGELOG" = true ] && [ "$HAS_PUBSPEC" = true ]; then
        echo -e "${GREEN}🎉 检查通过！代码、CHANGELOG.md 和 pubspec.yaml 都已更新${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  检查完成，但建议更新相关文件${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✅ 检查完成${NC}"
    exit 0
fi 