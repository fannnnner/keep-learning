# keep-learning

我个人维护的 Claude Code skill 集合，主题是"学会怎么学"。一条 curl 装好所有 skill，`git pull` 自动更新。

## 安装

**方式 1：curl 装所有 skill（推荐）**

```bash
curl -sSL https://raw.githubusercontent.com/fannnnner/keep-learning/main/install.sh | bash
```

clone 仓库到 `~/.keep-learning/`，按 symlink 安装到 `~/.claude/skills/`。装好后重启 Claude Code 就能用。再跑一次等于更新。

**方式 2：直接下载单个 `.skill` 文件**

仓库根目录有打包好的 `.skill` 文件，可以直接下载装：

```bash
curl -LO https://github.com/fannnnner/keep-learning/raw/main/meta-learn.skill
# 然后用 Claude Code 的 /skills install 或手动解压到 ~/.claude/skills/
```

适合：不想装整个仓库，只要某个 skill；或者分享给别人装单个 skill。

**改装到别的目录**（仅方式 1）：

```bash
KEEP_LEARNING_SKILLS_DIR=~/.kiro/skills \
  curl -sSL https://raw.githubusercontent.com/fannnnner/keep-learning/main/install.sh | bash
```

## 卸载

```bash
bash ~/.keep-learning/uninstall.sh
```

会列出要删的 symlink 让你确认，然后清掉 symlink 和缓存目录。加 `--yes` 跳过确认，加 `--keep-cache` 只删 symlink 保留 git 仓库缓存。

## 当前 skill

| Skill | 说明 |
|---|---|
| [`meta-learn`](skills/meta-learn/) | 六步结构化学习教练：定位 → 建地图 → 苏格拉底式对话 → 交错验证 → 按知识类型分支实践 → 整合到知识网络。把 Claude 从"倾倒信息"变成"引导主动重构心智模型"。 |

完整元数据看 [`registry.yaml`](registry.yaml)。

## 工作原理

- **Symlink 安装**：`~/.claude/skills/<name>` → `~/.keep-learning/skills/<name>`。`git pull` 后无需重装。
- **显式 manifest**：只装 `registry.yaml` 里列出的 skill，实验中的 skill 可以留在仓库里不干扰用户。
- **缓存目录** `~/.keep-learning/` 是整个仓库的只读副本。所有 skill 文件的权威来源在 GitHub。

## 加新 skill

1. 在 `skills/<name>/` 下放 `SKILL.md`（可选 `references/`、`scripts/` 等）
2. 在 `registry.yaml` 的 `skills:` 下加一条
3. 跑 `./build.sh` 生成对应的 `<name>.skill` 文件
4. commit + push（把源文件和 `.skill` 一起提交）
5. 本地跑一次 `curl ... | bash` 就能拉到新 skill

## 改已有 skill

1. 改 `skills/<name>/` 下的文件
2. 跑 `./build.sh <name>` 重新打包 `.skill`
3. commit + push

由于安装用的是 symlink，远程 `git pull` 后本地立刻生效。本地如果对某个 skill 做了直接修改（不是 commit 到仓库），`install.sh` 再次运行时会以仓库版为准覆盖——本地修改请走 PR，不要直接改安装后的文件。

## 兼容性

- macOS / Linux
- 依赖：`bash`、`git`、`awk`（系统默认都有）
- Claude Code 用户级 skill 目录：`~/.claude/skills/`

## License

MIT
