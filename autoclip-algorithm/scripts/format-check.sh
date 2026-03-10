#!/bin/bash

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root" || exit

. .venv/bin/activate

exit_code=0

echo "ruff format"
ruff format .

echo "ruff check"
ruff check --fix . || exit_code=1

echo "pyright check"
pyright --project . || exit_code=1

exit $exit_code