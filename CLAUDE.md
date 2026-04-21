# CLAUDE.md — 工作上下文

给未来接手这个仓库的 Claude/agent 会话看的。不是 README（那个给人装东西用）。这里讲的是**你改这个仓库时别把哪些事搞砸**。

## 这个仓库是什么

Fan 维护的个人 Claude Code skill 集合。**一个仓库 = 多个 skill + 一键安装脚本**。当前只有一个 skill：`meta-learn`（结构化学习教练）。

发布方式：GitHub 公开仓库，一条 curl 命令 clone 到 `~/.keep-learning/` 并 symlink 到 `~/.claude/skills/`。`git pull` 后本地立刻生效。

## 目录结构

```
.
├── CLAUDE.md              ← 你现在读的（给 AI 看的工作上下文）
├── README.md              ← 给人看的安装文档
├── LICENSE                ← MIT
├── install.sh             ← curl 安装入口（clone + symlink）
├── uninstall.sh           ← 确认式卸载
├── build.sh               ← 把 skills/<name>/ 打包成 <name>.skill
├── registry.yaml          ← 显式 manifest，列出哪些 skill 该装
├── meta-learn.skill       ← 预打包的 zip，21KB，必须和源文件同步
└── skills/
    └── meta-learn/
        ├── SKILL.md           ← 主文件（Claude Code 触发用）
        └── references/        ← 按需加载，主文件指向这些
            ├── step3_protocol.md       ← 关键：每进新模块前重读，对抗 drift
            ├── map_quality_protocol.md
            ├── practice_modes.md
            └── research_citations.md
```

## ⚠️ 唯一最重要的不变式

**改了 `skills/<name>/` 下任何源文件，必须跑 `./build.sh <name>` 重建 `.skill`，然后和源文件一起 commit。**

忘了这一步 → `.skill` 文件和源文件不同步 → 通过方式 2（直接下载 `.skill`）装的用户拿到的是旧版。

```bash
# 标准改动流程
vim skills/meta-learn/SKILL.md
./build.sh meta-learn
git add -A && git commit -m "..." && git push
```

## Skill 设计约定（改 SKILL.md 时遵守）

### 1. 不要擅自"优化"——只做用户明确要求的事

历史教训：前任 agent 被授权做"拆 references/"的结构重构，结果顺手把 5 处内容删了（包括关键的锚点评估判断依据）。用户发现后极其不满。

**规则**：任何对 SKILL.md 的修改必须是**surgical**：
- 用户要求 A，你只做 A，不做 A+B+C
- 删除任何 prose 段落前问一下（即使看起来"冗余"）
- 不要把"绝对不要"改成"绝不"这种"美化"——这不是授权范围

如果你在 diff 里看到 10 处修改但用户只要求 2 处，**停下来报告**。

### 2. Step 3 是特殊的 —— 不要把它搬回主文件

`skills/meta-learn/references/step3_protocol.md` 单独存在是为了**对抗长会话 drift**：Step 3 是循环使用的协议（10-30 次循环），主 SKILL.md 里的路由指令要求 Claude **每进新模块前重读一次**这个 reference 文件，把协议重新提到"最近上下文"。

**不要**：
- 把 step3_protocol.md 的内容搬回 SKILL.md 主体（那就失去了 reload 触发点）
- 在 SKILL.md 里复制一份 Step 3 内容（双来源会让模型困惑选哪个）

**要做的**：如果 Step 3 协议本身要改，改 `step3_protocol.md`。SKILL.md 里的路由指令除非路由逻辑本身变了，否则别动。

### 3. References 的加载模式

- `step3_protocol.md`：**周期性重读**（每模块一次）
- `map_quality_protocol.md`：**按需一次**（进 Step 2 时读一次即可）
- `practice_modes.md`：**按需一次**（进 Step 5 时按知识类型只读对应的 A/B/C 段）
- `research_citations.md`：**几乎不用**（只在用户质疑某个设计的必要性时查）

搞混这些加载模式会破坏 token 经济学。

### 4. 内联研究引用（`（研究依据：...）`）

保留原样，别折腾。它们是用户精心放置的锚点，不是"可以精简的噪音"。`research_citations.md` 是补充汇总，不是替代。

## 测试模式（改完 SKILL.md 怎么验证）

历史上验证 skill 改动的方法是 **subagent 行为测试**：

1. 起一个 subagent，让它"假装自己是加载了 meta-learn skill 的 Claude"
2. 给它一个用户 prompt
3. 要求它把回复 + 读过的文件列表写到 `/tmp/` 下
4. 检查两件事：
   - 回复是否符合 skill 的意图（比如 Step 1 opening 不该 dump 知识）
   - 读文件的模式是否正确（比如进 Step 3 应该读 `step3_protocol.md`）

参考：上一轮改 step3 reload 机制时，用 3 个 subagent（smoke / entry / reread）在 `/tmp/step3-tests/` 下跑了验证。

如果用户没明确要求测试但你做了一个结构性改动（比如拆新的 reference），**主动跑一下 subagent 测试再 commit**。

## 发布流程

**标准**：改源 → `./build.sh` → commit → push（走当前登录的 gh CLI）。

**Token**：用户的 PAT 不在这个仓库里，也不落盘到 git config。需要临时 push 时用 `GH_TOKEN=... git -c credential.helper='...'  push` 这种一次性注入。不要把 token 写到任何文件。

## 加新 skill 的流程

1. `mkdir -p skills/<name>/references`
2. 写 `skills/<name>/SKILL.md`（带 frontmatter：name、description）
3. 在 `registry.yaml` 的 `skills:` 下加一条（name + path 两个字段是 install.sh 要用的，其他字段是给人看的）
4. `./build.sh <name>` 生成 `<name>.skill`
5. commit + push

## 兼容性要点

- `install.sh` / `build.sh` 必须 **macOS bash 3.2 兼容**（用户在 macOS 上）。别用 `readarray`、`mapfile`、`&>`、进程替换里的数组等 bash 4+ 特性。
- 脚本依赖：`bash`、`git`、`awk`、`zip`（macOS/Linux 系统默认都有，别引入 Python/jq/yq）。

## 不做的事

- **不改 CLAUDE.md、README.md、install.sh、uninstall.sh、build.sh 的表达风格**，除非用户明确说要
- **不加自动化**（pre-commit hook、GitHub Actions、cron）除非用户明确说要
- **不引入新依赖**（Python、jq、yq 等）除非必要
- **不"发布 GitHub Release"**，当前仓库就是分发渠道本身
