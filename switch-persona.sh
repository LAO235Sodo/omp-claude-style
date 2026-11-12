#!/usr/bin/env bash
# omp 人格切换器：claude 风格 <-> 内置 default，互不覆盖
#
# 用法:
#   bash switch-persona.sh claude   # 切到 claude 风格（写入覆盖文件）
#   bash switch-persona.sh default  # 切回内置 default（移除覆盖文件，原预设零改动）
#   bash switch-persona.sh status   # 查看当前档位
#
# 原理: omp 的 PERSONALITY.md / APPEND_SYSTEM.md 是"覆盖文件"——
#   存在 = claude 风格生效；移除 = 回落到内置 default 预设（无需复制 default，零漂移）。
# 生效时机: 系统提示在会话启动时渲染 → 新开会话生效，已开的会话不受影响，
#   所以可以先开一个 default 会话、切换、再开一个 claude 会话，两种人格并发使用。
set -euo pipefail

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

status() {
  if [[ -e "$AGENT_DIR/PERSONALITY.md" || -e "$AGENT_DIR/APPEND_SYSTEM.md" ]]; then
    echo "当前档位: claude 风格"
  else
    echo "当前档位: 内置 default"
  fi
}

case "${1:-status}" in
  claude)
    if [[ -e "$script_dir/PERSONALITY.md" && -e "$script_dir/APPEND_SYSTEM.md" ]]; then
      SRC="$script_dir"
    elif [[ -e "$HOME/Downloads/project/omp-claude-style/PERSONALITY.md" ]]; then
      SRC="$HOME/Downloads/project/omp-claude-style"
    else
      echo "错误: 找不到 PERSONALITY.md/APPEND_SYSTEM.md 源（请在 omp-claude-style 仓库内运行）" >&2
      exit 1
    fi
    mkdir -p "$AGENT_DIR"
    cp "$SRC/PERSONALITY.md" "$SRC/APPEND_SYSTEM.md" "$AGENT_DIR/"
    echo "已切换: claude 风格（新会话生效）"
    ;;
  default)
    rm -f "$AGENT_DIR/PERSONALITY.md" "$AGENT_DIR/APPEND_SYSTEM.md"
    echo "已切换: 内置 default（覆盖文件已移除，新会话生效）"
    ;;
  status)
    ;;
  *)
    echo "用法: bash switch-persona.sh claude|default|status" >&2
    exit 1
    ;;
esac
status
