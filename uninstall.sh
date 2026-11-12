#!/usr/bin/env bash
# 回滚：优先恢复最近一次 install.sh 的备份；无备份则删除覆盖文件
set -euo pipefail

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

for f in PERSONALITY.md APPEND_SYSTEM.md; do
  latest_bak="$(ls -t "$AGENT_DIR/$f".bak-* 2>/dev/null | head -1 || true)"
  if [[ -n "$latest_bak" ]]; then
    mv "$latest_bak" "$AGENT_DIR/$f"
    echo "已回滚 $f（恢复自 $(basename "$latest_bak")）"
  elif [[ -e "$AGENT_DIR/$f" ]]; then
    rm "$AGENT_DIR/$f"
    echo "已删除 $AGENT_DIR/$f"
  else
    echo "$f 不存在，跳过"
  fi
done

echo "新会话生效。"
