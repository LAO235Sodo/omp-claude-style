#!/usr/bin/env bash
# 安装 omp Claude 风格覆盖：PERSONALITY.md + APPEND_SYSTEM.md -> ~/.omp/agent/
# 含：机制前置检查、已有文件时间戳备份、SYSTEM 自定义提示冲突告警
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

command -v omp >/dev/null 2>&1 || { echo "错误: 未找到 omp，请先安装 omp"; exit 1; }
OMP_BIN="$(readlink -f "$(command -v omp)")"
echo "omp: $OMP_BIN"
echo "agent 目录: $AGENT_DIR"

for marker in PERSONALITY.md APPEND_SYSTEM.md; do
  if strings -a "$OMP_BIN" 2>/dev/null | grep -q "$marker"; then
    echo "机制检查: $marker 发现机制存在 ✓"
  else
    echo "警告: omp 二进制未发现 $marker 机制，安装后可能不生效（omp 版本过旧？）"
  fi
done

mkdir -p "$AGENT_DIR"
for f in PERSONALITY.md APPEND_SYSTEM.md; do
  if [[ -e "$AGENT_DIR/$f" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    echo "备份: $f -> $f.bak-$ts"
    mv "$AGENT_DIR/$f" "$AGENT_DIR/$f.bak-$ts"
  fi
  cp "$SRC_DIR/$f" "$AGENT_DIR/$f"
  echo "已写入: $AGENT_DIR/$f"
done

for conflict in SYSTEM.md SYSTEM_TEMPLATE.md; do
  if [[ -e "$AGENT_DIR/$conflict" ]]; then
    echo "警告: 检测到 $AGENT_DIR/$conflict —— 自定义 SYSTEM 提示会替换默认指令块，"
    echo "       PERSONALITY.md 将不生效；APPEND_SYSTEM.md 仍生效。"
  fi
done

cat <<'EOF'

完成。注意：
- 系统提示在会话启动时渲染：新开会话（或重启 omp）生效，当前会话不变。
- task 子代理恒为 personality none，不受影响。
- 验证: bash verify-ab.sh
- 回滚: bash uninstall.sh
EOF
