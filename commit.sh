#!/bin/bash
# commit.sh — 用 fannnnner 身份 commit，不改任何 git config
#
# 为什么存在：这台机器的全局 git config 是工作邮箱（xiaolong.fan@dcsserv.com），
# 该邮箱在 GitHub 挂在另一个账号（fanxiaolong123）。直接 git commit 会让这个
# 仓库的 commit 在 GitHub 上挂在错误的账号下。
#
# 这个脚本通过 --author 和 GIT_COMMITTER_* 环境变量一次性覆盖作者/提交者，
# 完全不碰 .git/config（本地）或 ~/.gitconfig（全局），工作项目不受影响。
#
# 用法：
#   ./commit.sh -m "提交信息"
#   ./commit.sh -m "$(cat <<'EOF'
#   多行提交信息
#   可以这样写
#   EOF
#   )"
#   ./commit.sh --amend            # 其他 git commit 参数照传
#
# 所有参数透传给 git commit。

set -euo pipefail

AUTHOR_NAME="fannnnner"
AUTHOR_EMAIL="174702197+fannnnner@users.noreply.github.com"

GIT_COMMITTER_NAME="$AUTHOR_NAME" \
GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL" \
git commit --author="${AUTHOR_NAME} <${AUTHOR_EMAIL}>" "$@"
