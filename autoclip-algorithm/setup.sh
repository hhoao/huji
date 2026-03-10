#!/bin/bash
set -e

# 设置venv环境
python3 -m venv .venv
source .venv/bin/activate

echo "🚀 Setting up development environment..."

# 安装依赖
echo "📦 Installing dependencies..."
pip install -r requirements.txt
pip install pre-commit ruff pyright

# 安装 pre-commit 钩子
echo "🪝 Installing pre-commit hooks..."
pre-commit uninstall && pre-commit install && pre-commit install --hook-type commit-msg

# 运行一次检查
echo "🧪 Running initial check..."
pre-commit run --all-files

echo "✅ Setup complete! Pre-commit hooks are now active."