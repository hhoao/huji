#!/bin/bash

# 提交信息检查脚本
# 使用方法：将此脚本放在 .git/hooks/commit-msg 中，或者手动运行

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取提交信息文件路径
COMMIT_MSG_FILE="$1"

# 如果没有提供文件路径，使用默认的
if [ -z "$COMMIT_MSG_FILE" ]; then
    COMMIT_MSG_FILE=".git/COMMIT_EDITMSG"
fi

# 读取提交信息
if [ -f "$COMMIT_MSG_FILE" ]; then
    COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
else
    echo -e "${RED}错误: 找不到提交信息文件${NC}"
    exit 1
fi

echo -e "${BLUE}检查提交信息:${NC}"
echo "$COMMIT_MSG"
echo ""

# 检查规则
ERRORS=0
WARNINGS=0

# 规则1: 检查提交信息是否为空
if [ -z "$COMMIT_MSG" ]; then
    echo -e "${RED}❌ 错误: 提交信息不能为空${NC}"
    ((ERRORS++))
fi

# 规则2: 检查提交信息长度（第一行不超过50字符）
FIRST_LINE=$(echo "$COMMIT_MSG" | head -n 1)
if [ ${#FIRST_LINE} -gt 50 ]; then
    echo -e "${RED}❌ 错误: 提交信息第一行不能超过50个字符 (当前: ${#FIRST_LINE})${NC}"
    echo "   $FIRST_LINE"
    ((ERRORS++))
fi

# 规则3: 检查是否以类型前缀开头
VALID_TYPES=("feat" "fix" "docs" "style" "refactor" "test" "chore" "perf" "ci" "build" "revert")
HAS_VALID_PREFIX=false

for type in "${VALID_TYPES[@]}"; do
    if [[ "$FIRST_LINE" =~ ^$type[\(:].* ]]; then
        HAS_VALID_PREFIX=true
        break
    fi
done

if [ "$HAS_VALID_PREFIX" = false ]; then
    echo -e "${YELLOW}⚠️  警告: 建议使用标准的提交类型前缀${NC}"
    echo "   有效的类型: ${VALID_TYPES[*]}"
    echo "   示例: feat: 添加新功能, fix: 修复bug, docs: 更新文档"
    ((WARNINGS++))
fi

# 规则4: 检查是否包含版本号（可选）
if [[ "$COMMIT_MSG" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${GREEN}✅ 包含版本号${NC}"
else
    echo -e "${YELLOW}⚠️  提示: 可以考虑在提交信息中包含版本号${NC}"
    ((WARNINGS++))
fi

# 规则5: 检查是否以句号结尾
if [[ "$FIRST_LINE" =~ \.$ ]]; then
    echo -e "${YELLOW}⚠️  警告: 提交信息第一行不应该以句号结尾${NC}"
    ((WARNINGS++))
fi

# 规则6: 检查是否使用祈使语气
if [[ "$FIRST_LINE" =~ ^[a-z] ]]; then
    echo -e "${GREEN}✅ 使用祈使语气${NC}"
else
    echo -e "${YELLOW}⚠️  建议: 使用祈使语气 (如 'add' 而不是 'added')${NC}"
    ((WARNINGS++))
fi

# 规则7: 检查是否包含详细的描述（如果有第二行）
LINE_COUNT=$(echo "$COMMIT_MSG" | wc -l)
if [ "$LINE_COUNT" -gt 1 ]; then
    SECOND_LINE=$(echo "$COMMIT_MSG" | sed -n '2p')
    if [ -n "$SECOND_LINE" ] && [ ${#SECOND_LINE} -lt 10 ]; then
        echo -e "${YELLOW}⚠️  提示: 第二行描述可以更详细一些${NC}"
        ((WARNINGS++))
    fi
fi

# 规则8: 检查是否包含特殊字符
if [[ "$COMMIT_MSG" =~ [^\x00-\x7F] ]]; then
    echo -e "${GREEN}✅ 包含中文描述${NC}"
fi

# 显示结果
echo ""
echo "=================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 提交信息检查通过！${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  提交信息检查完成，有 $WARNINGS 个警告${NC}"
    echo -e "${YELLOW}   建议修复这些警告，但不会阻止提交${NC}"
    exit 0
else
    echo -e "${RED}❌ 提交信息检查失败，有 $ERRORS 个错误${NC}"
    echo -e "${RED}   请修复这些错误后重新提交${NC}"
    exit 1
fi 