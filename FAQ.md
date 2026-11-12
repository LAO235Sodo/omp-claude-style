# FAQ · 实测结论沉淀

本仓库落地过程中的问答结论，全部有实测或二进制验证依据（omp 18.19.0 + Claude Code 2.1.322，2026-11-12）。

## Q1：引入这些提示语，带来什么变化？有用吗？

三轮 A/B 对照（同模型、同问题、唯一变量 = 两个覆盖文件，`verify-ab.sh` 可复现）：

| 探针类型 | 基线（默认人格） | 启用覆盖后 | 变化幅度 |
|---|---|---|---|
| 讲解类（浏览器同源策略） | 要点式、较克制 | 完整讲解 + 主动延伸应用场景 | **大** |
| 闲聊观点类（AI 助手的坑） | 加粗小标题+要点碎片、`[INFERENCE]` 机械标注 | 连贯散文长文、机械痕迹消失 | **最大** |
| 任务执行类（bash 单行命令） | 命令 + 一段说明 | 同形态，无啰嗦 | **几乎为零** ✓ |

**变化集中在讲解/讨论场景**（目标场景）；任务执行无形态变化。

判断口径：主要用 omp 讲解/讨论/学习 → 有用；主要跑自动化编码任务 → 几乎无感知。成本 = 讲解类回答变长（token 增加，即设计意图本身）。诚实边界：每组 n=1，证明方向与形态，非统计显著性（对照中覆盖组曾给出更精确命令，属单次采样运气，不作归因）。

## Q2：PERSONALITY.md 属于哪个人格？影响哪个人格？

**挂在当前选中的预设档位上，不是第四预设。** `personality` 配置选的是 `default` → 它替换 default 预设文本；切成 `friendly` → 替换 friendly 文本。例外：`personality: none` → 人格块整体省略，PERSONALITY.md 不渲染（APPEND_SYSTEM.md 仍生效）。

| 会话类型 | PERSONALITY.md | APPEND_SYSTEM.md |
|---|---|---|
| 主会话 | ✅ 唯一生效点 | ✅ 生效 |
| task 子代理 | ❌ 恒为 none（omp 硬编码），永不渲染 | ❌ 不继承 |
| advisor/watchdog | ❌ 恒为 none | ❌ 不注入 |
| 会话标题生成 | ❌ 走独立 TITLE_SYSTEM.md | ❌ |

注意：因为覆盖骑在 `default` 档上，内置 friendly/pragmatic 预设会被顶掉——想多预设真并存走 Q4。

## Q3：omp 有现成的人格插件/技能吗？

**没有。** 实测依据：

- `omp skill search persona` / `search personality` → 均返回 No skills found（官方 registry）
- 二进制字符串区无 `/personality` 会话内切换命令（只有 "personality preset" 回退告警文案）
- 内置人格是固定 4 档 enum：`default | friendly | pragmatic | none`，**不可自增命名预设**

原生可用的 5 条机制：

| 机制 | 粒度 | 切换方式 |
|---|---|---|
| 内置 4 档人格 | 全局 | config.yml `personality:` 键 |
| PERSONALITY.md 覆盖 | 全局单档 | 本仓库方案 |
| **Profile 多人格** | 完全隔离环境 | `omp --profile <名> --alias <快捷名>` |
| 按需技能型人格 | 会话中途可加载 | `/skill:<名>`（需自建，registry 暂无） |
| systemPromptTemplates | 按模型 | config.yml 映射表 |

## Q4：想「default 保持原样 + claude 风格单独一档」怎么选路线？

两条路线，按需选：

| | 切换器（本仓库 `switch-persona.sh`） | Profile 路线 |
|---|---|---|
| 原理 | 移除/写入覆盖文件，回落**编译在二进制里的原生 default**（零复制、零漂移） | `~/.omp/profiles/<名>/agent/` 独立目录各放一份 |
| default 是否被改 | ❌ 永不（无副本滞后问题） | ❌ 永不 |
| 会话历史/模型配置 | 共用一套 | **完全隔离，各自一份** |
| 并发 | ✅ 两种人格可同时开不同会话 | ✅（`omp` 与 `omp-claude` 两个命令） |
| 适用 | **只换说话风格** | 真要两套工作环境 |

决策口径：只换说话风格 → 切换器；要隔离环境 → profile。

## Q5：已知边界汇总

- 系统提示在**会话启动时**渲染：切换后新会话生效，已开会话不变
- 与仓库规则冲突的 Claude 原句（"不要把用户批评当真"）已剔除——适配你自己的环境时同样检查 AGENTS/CLAUDE 约定
- 提示词段落提取自本机已安装的 Claude Code 二进制，版权归 Anthropic，仅个人配置用途
