#!/bin/bash

# 设置默认语言环境
export LANG=C
export LC_ALL=C

# 获取提交信息
commit_msg=$(cat "$1")

echo "commit_msg: $commit_msg"

# 定义提交类型
types=("feat" "fix" "docs" "style" "refactor" "perf" "test" "chore" "revert" "ci" "build")

# 检查提交信息格式 (scope 现在是可选的)
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|chore|revert|ci|build)(\([a-z]+\))?: .+"; then
    echo "❌ commit message format error!"
    echo "correct format should be: <type>(<scope>): <subject>"
    echo "note: <scope> is optional"
    echo ""
    echo "type types:"
    echo "  feat     - new feature"
    echo "  fix      - fix bug"
    echo "  docs     - update docs"
    echo "  style    - code style"
    echo "  refactor - refactor"
    echo "  perf     - performance"
    echo "  test     - add test"
    echo "  chore    - build process or auxiliary tool"
    echo "  revert   - revert"
    echo "  ci       - CI config"
    echo "  build    - build"
    echo ""
    echo "example:"
    echo "  feat(auth): add user login functionality"
    echo "  fix(api): resolve timeout issue"
    echo "  docs(readme): update installation instructions"
    echo "  feat: add new feature without scope"
    exit 1
fi

# 检查type是否小写
type=$(echo "$commit_msg" | grep -oE "^(feat|fix|docs|style|refactor|perf|test|chore|revert|ci|build)")
if [[ "$type" != "$(echo "$type" | tr '[:upper:]' '[:lower:]')" ]]; then
    echo "❌ type must be lowercase!"
    exit 1
fi

# 检查scope是否小写 (如果存在)
if echo "$commit_msg" | grep -qE "\([a-z]+\)"; then
    scope=$(echo "$commit_msg" | grep -oE "\([a-z]+\)" | tr -d '()')
    if [[ "$scope" != "$(echo "$scope" | tr '[:upper:]' '[:lower:]')" ]]; then
        echo "❌ scope must be lowercase!"
        exit 1
    fi
fi

echo "✅ commit message format is correct!"
exit 0
