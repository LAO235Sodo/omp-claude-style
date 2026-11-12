#!/usr/bin/env bash
# A/B 验证：移走覆盖文件跑基线，恢复后再跑同一问题，并排对比回答风格
# 用法: bash verify-ab.sh ["你的问题"]
# 消耗: 两次小模型调用（走 omp default 角色）
set -euo pipefail

AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
QUESTION="${1:-随便聊聊：你觉得 AI 编程助手最大的坑是什么？}"
STASH="$(mktemp -d)"

moved=0
for f in PERSONALITY.md APPEND_SYSTEM.md; do
  if [[ -e "$AGENT_DIR/$f" ]]; then
    mv "$AGENT_DIR/$f" "$STASH/$f"
    moved=1
  fi
done

if [[ "$moved" -eq 0 ]]; then
  echo "错误: $AGENT_DIR 下未发现 PERSONALITY.md / APPEND_SYSTEM.md，请先 bash install.sh"; exit 1
fi

echo "== A/B 1/2: 基线（无覆盖），调用中..."
omp -p --auto-approve "$QUESTION" > "$STASH/baseline.txt" 2>&1 || true

[[ -e "$STASH/PERSONALITY.md" ]] && mv "$STASH/PERSONALITY.md" "$AGENT_DIR/"
[[ -e "$STASH/APPEND_SYSTEM.md" ]] && mv "$STASH/APPEND_SYSTEM.md" "$AGENT_DIR/"

echo "== A/B 2/2: 启用覆盖，调用中..."
omp -p --auto-approve "$QUESTION" > "$STASH/with.txt" 2>&1 || true

strip() { sed 's/^Working\.\.\.$//' "$1" | sed '/^$/d'; }

echo
echo "========== 基线（默认 terse 人格） =========="
strip "$STASH/baseline.txt"
echo
echo "========== 启用覆盖后（Claude 风格） =========="
strip "$STASH/with.txt"
echo
echo "判定特征：基线应为「小标题+要点碎片」，覆盖后应为「连贯散文式完整讲解」。"
echo "原始输出保留在: $STASH"
