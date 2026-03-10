#!/bin/bash

check_code() {
    if [ $1 -ne 0 ]; then
        echo -e "\033[31m$error_msg\033[0m"
        exit $1
    fi
}

exit_code=0
error_msg=""

echo "开始格式化"
error_msg="格式化失败"
dart format --set-exit-if-changed . || exit_code=1
check_code $exit_code || exit $exit_code
echo "格式化完成"

echo "开始修复"
error_msg="修复失败"
dart fix --dry-run || exit_code=1
check_code $exit_code || exit $exit_code
echo "修复完成"

echo "开始分析"
error_msg="分析失败"
dart analyze || exit_code=1
check_code $exit_code || exit $exit_code
echo "分析完成"

exit $exit_code