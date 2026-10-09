# 《你的按钮我来藏》项目审计报告（最终）

| | |
|---|---|
| 审计日期 | 2026-10-09 |
| 审计对象 | `D:\桌面\guyu\项目2`（命名空间 `ybih`） |
| 审计范围 | `src/`（160 文件 / 151 函数）、`tools/`、`.github/`、三份产物包 |
| 审计方式 | 静态审计：构建期校验 + **产物逐行取证**（命令原文取自解压后的 zip，非生成器源码）+ 逻辑推演 + 机械集合比对 |
| 执行 | 主审计 + 两个并行专项审计（九宫格棋子系统 / 核心游戏流程），三份结论由主审计逐条复核 |
| 代码状态 | 本报告描述的代码状态与提交 `965888a` 严格一致；审计全程**未修改任何代码文件** |
| 修复状态 | 报告内 16 条缺陷**已全部修复**，见第十三节 |

> 阅读说明：第二～七节描述的是**审计当时（提交 `965888a`）**的代码状态，其中的命令原文是缺陷证据，
> 已经不再与当前代码一致。当前代码对应的修复做法见**第十三节**。

---

## 〇、结论摘要

**项目整体健康，无致命缺陷** —— 不会卡死、不会数据错乱、不会功能完全失效。

| 级别 | 数量 | 编号 |
|---|---|---|
| 致命 | **0** | — |
| 中等（当前可达） | **3** | M1 M2 M3 |
| 中等（潜伏，当前不可达） | **1** | P1 |
| 轻微 | **7** | L1–L7 |
| 文档与实现不一致 | **2** | D1 D2 |
| 工程隐患 | **4** | E1–E4 |
| 已排除的怀疑 | **8** | X1–X8 |
| 待实测 | **11** | T1–T11 |

### 健康面（已机械核验）

- 三个包构建**退出码 0**，文件数 491 / 491 / 246，按钮 10 / 13 / 14 种
- 产物 CRC 全部 OK，`pack.mcmeta` 均在压缩包根部；重构建产物与 `dist/` **清单逐项一致**，`dist` 非陈旧
- 151 个函数引用**全部可解析**，无悬空引用；未替换占位符 **0 处**；非法转义 **0 处**；漏逗号 **0 处**
- 文本方言**零交叉污染**（包 1/2 用 JSON、包 3 用 SNBT，各用各的）
- 阶段状态机 `0 → 1 ⇄ 2 → 3 → 4 → 1/0` **全分支闭合**
- `ttt_reset` 的「写入集合 vs 清零集合」**双向差集为空**
- 三包版本适配（`pack_format` 6/41/71、目录单复数、触发器名、物品组件、书页语法）**逐项正确**
- 低版本包中高版本专有语法 **0 处**

---

## 一、缺陷总表

| 编号 | 级别 | 位置 | 一句话结论 | 复核 |
|---|---|---|---|---|
| **M1** | 中等 | `room/ttt_leave:6-9`、`ttt_decline:5-8`、`ttt_cancel:5-8` | 离座时对手收不到任何通知，之后点格子**彻底静默** | 主审计逐条复核 ✅ |
| **M2** | 中等 | `room/ttt_tick:14`、`ttt_seat:19-30,33-44` | 掉线者名单位被顶替后重连，**同槽位两人**，一人从名单消失 | 主审计逐条复核 ✅ |
| **M3** | 中等 | `game/enter_searching_classic:15` | 阈值 `..1` 过宽，2 人局里**该进行的搜寻被整个跳过** | 主审计逐条复核 ✅ |
| **P1** | 中等（潜伏） | `player/leave_game` | 摘 `ybih_player` 但不清棋类状态，可留幽灵对手 | 主审计发现 |
| L1 | 轻微 | `button/trigger_run:4,33` | 非藏匿阶段点【确认】/【取消重放】被静默吞掉，无回执 | 主审计复核 ✅ |
| L2 | 轻微 | `game/cleanup_end:37` 等 3 处 | `ybih_presser` 是**只减不增的死标签** | 主审计复核 ✅ |
| L3 | 轻微 | `game/turn_timeout:23` | `#hide_owed` 只能记**一笔**欠账，连续两人超时掉线时先欠的被覆盖 | 主审计复核 ✅ |
| L4 | 轻微 | `room/ttt_board:101` | 对局中的棋盘**自带不带**【离座】（其他入口都在，功能不缺） | 主审计复核 ✅ |
| L5 | 轻微 | `button/trigger_run:33` | 受理范围 `11..52` 大于实际发出范围（`14..19`/`33..40` 无人发出） | 主审计复核 ✅ |
| L6 | 轻微 | `room/ttt_verify:28` | 一处注释指向与实现不符（行为无影响） | 主审计复核 ✅ |
| L7 | 轻微 | `util/cleanup_all:33` | `clear @a #minecraft:buttons` 会清玩家背包按钮，与 README 口径不一致 | 主审计复核 ✅ |
| D1 | 文档 | `ybih_memory.md` 第十七节 | 记「全库只有两处 `enable`」，实际 **5 处** | 主审计复核 ✅ |
| D2 | 文档 | `README.md:308` | 称「不会去动地图自带按钮」，但 `cleanup_all` 会清全服背包 | 见 L7 |
| E1 | 隐患 | `tools/verify_zips.py:37-49,78` | 新鲜度检查只遍历 `src/`，**漏了 `tools/`**（生成器都在那儿） | 主审计实验复现 ✅ |
| E2 | 隐患 | `ybih.t_first` vs `ybih.tfirst` | 两个记分项只差一个下划线、语义完全不同 | 主审计发现 |
| E3 | 隐患 | `button/trigger_run:16-29` | 棋类分派靠第一行**间接**兜住，缺显式 `#state = 2` | 主审计推演 ✅ |
| E4 | 隐患 | `room/ttt_abort:8,31-47` | `#topp = 0` 时匹配面扩到所有 id=0 的玩家（未找到可达路径） | 主审计发现 |

---

## 二、中等缺陷（当前可达，建议优先修）

### M1 离座时对手收不到任何通知，之后点格子彻底静默

**位置**
- `src/data/ybih/function/room/ttt_leave.mcfunction:6-9`
- `src/data/ybih/function/room/ttt_decline.mcfunction:5-8`
- `src/data/ybih/function/room/ttt_cancel.mcfunction:5-8`
- `src/data/ybih/function/room/ttt_abort.mcfunction:8`

**问题**：`#t_quiet = 1` 抑制掉的那句通知，**收件人不是离座者本人，而是对手**。

`ttt_abort:8` 的实际命令（取自产物）：

```
execute if score #t_quiet ybih.ttt matches 0 as @a if score @s ybih.id = #topp ybih.ttt if score @s ybih.topp = #me ybih.ttt run tellraw @s {"text":"对手不在了，这一局作废，可以重新挑人","color":"yellow"}
```

执行上下文拆解：`as @a` 把执行者换成**遍历到的那个玩家**，随后两个 `if` 要求「他就是我的对手、且他也指着我」，所以 `run tellraw @s` 里的 `@s` 是**对手**。

而 `ttt_leave` 先置了 `#t_quiet = 1`：

```
scoreboard players set #t_quiet ybih.ttt 1
execute if score @s ybih.tstate matches 1.. run tellraw @s {"text":"你退出了这一局","color":"yellow"}
function ybih:room/ttt_abort
scoreboard players set #t_quiet ybih.ttt 0
```

**该文件的注释（「免得同一件事提示两遍」）与实际行为不符** —— 被压掉的不是重复提示，而是对手能收到的**唯一**一条通知。

**后果**：`ttt_abort:11-27`（清自己）与 `31-47`（清对手）不受 `#t_quiet` 约束，照常执行。对手的 `tstate`/`tres`/`t1..t9` 被**静默清零**，而他屏幕上的棋盘仍显示「对局中」。

他随后点任意格子时，`ttt_click:44-45` 的两条说明**都命不中**：

```
execute if score #t_pick ybih.ttt matches 0 if score @s ybih.tres matches 1..3 run tellraw @s {"text":"这局已经下完了，点【再来一局】或【离座】",...}
execute if score #t_pick ybih.ttt matches 0 if score @s ybih.tres matches 0 if score @s ybih.tstate matches 3 run tellraw @s {"text":"这一格现在落不下：要么没轮到你，要么已经落过了",...}
```

第 1 条要求 `tres = 1..3`（已被清成 0），第 2 条要求 `tstate = 3`（已被清成 0）；落子条件（`tstate=3`）同样不成立。**结果是彻底的静默无响应**，只能自己想起来点【刷新名单】才看到「你现在空闲」。

**复现**：A、B 开局 → A 点【离座】→ B 聊天栏无任何提示、棋盘仍显示对局中 → B 点格子，毫无反应。

**判定为缺陷而非设计的依据（关键证据）**：同一份代码里相反方向的处理**自相矛盾**。`ttt_invite_1.mcfunction:19` 在收掉自己的旧局时**显式归零** `#t_quiet`，注释写得很清楚：

```
# 那会让我这边静悄悄地走掉，旧对手干等着我点【再来一局】却不知道这局已经散了
scoreboard players set #t_quiet ybih.ttt 0
```

即：写 `ttt_invite` 时已识别出「不能让旧对手干等」，但三个入口仍是抑制的，没回头统一。

**严重程度差异**：`ttt_decline`、`ttt_cancel` 是同一处缺陷的另两个入口，但后果轻一档 —— 被邀请方点【同意】时会被 `ttt_accept.mcfunction:13` 拦下并告知「这个邀请已经失效了」，属可自恢复的滞后提示。**`ttt_leave`（对局中离座）后果最重**。

**建议修法**：把三个入口的 `#t_quiet` 处理对齐 `ttt_invite` 的做法（不抑制，或显式归零），让对手收到通知。

---

### M2 掉线者的名单位被顶替后重连，同一槽位出现两个人

**位置**
- `src/data/ybih/function/room/ttt_tick.mcfunction:14`（回收只够得到在线玩家）
- `src/data/ybih/function/room/ttt_seat.mcfunction:19-30, 33-44`（占用表只由在线玩家算出）
- `src/data/ybih/function/room/ttt_roster.mcfunction:12` 等（显示名用 `limit=1`）

**机理**：`@a` 遍历不到离线玩家。

| 环节 | 命令 | 后果 |
|---|---|---|
| 回收 | `as @a[tag=ybih_player,scores={ybih.rseat=1..}] unless entity @s[distance=..12]` | A 掉线时仍带 `rseat=5`，够不到他 |
| 统计 | `as @a[tag=ybih_player,scores={ybih.rseat=1},distance=..12]` → `#rs1` | A 不在 `@a` 里 ⇒ `#rs5 = 0` |
| 分派 | `unless score @s ybih.rseat matches 1.. if score #rs5 ybih.ttt matches 0` | B 拿到**同一个 5 号位** |

A 重连后仍在房内，`ttt_tick:14` 因「他就在房里」不再回收 ⇒ **两人同时持有 `rseat=5`**。

名单/状态/提示三处的显示名选择器都带 `limit=1`，只会渲染其中**任意一人**，另一人从名单上消失、别人点不到他。

**复现**：`#state=2` 期间 A 坐等待室时掉线 → B 进房（或有人点【刷新名单】）顶替 5 号位 → A 重连 → 第三人刷新名单，5 号行只剩一个名字。

**为何只是中等**：不会卡死。`ttt_verify:23-29` 的状态核对仍能把不一致的一方作废并给出提示。

**建议修法**：名单位分配需要能感知离线占用（例如把占用记在假玩家上并在离开房间时回收，或分配时避开「名单位已被他人 topps 指向」的槽位）。

---

### M3 `enter_searching_classic` 的按钮数阈值过宽，会跳过本应进行的搜寻阶段

**位置**：`src/data/ybih/function/game/enter_searching_classic.mcfunction:15`

```
execute if score #button_count ybih.config matches ..1 run function ybih:game/end_round
execute if score #button_count ybih.config matches 2.. run title @a title {{TXT_S}}开始搜寻{{TXT_M}}gold{{TXT_E}}
```

同文件第 5–12 行的注释写明判据意图：

```
# 只有一个人时场上没有「别人的按钮」可按：按钮的分只发给别人，
# 自己的按钮按了不给分，搜寻阶段没有事可做，直接跳过进入结算。
#
# 判据用「场上按钮数」而不是「在线人数」：……按钮数才真正对应「搜寻阶段有没有事可做」
```

**判据与意图不匹配**：「只有一个人」对应 `#player_count = 1`（此时按钮分值 `1 − 1 = 0`），而写法是 `#button_count ..1`，把「1 个按钮但有多人」也一并跳过。同文件第 3–4 行的动机表述（「只有一个人」）与第 14 行的判据表述（「不足 2 个按钮」）本身就不一致。

**复现推演**（2 人局，经典模式）：

| 步 | 事件 | 状态 |
|---|---|---|
| 1 | A、B 入队 | `#player_count = 2` |
| 2 | A 藏匿成功 | `confirm_place_ok:15-16` 写 `ybih.value = 2 − 1 = 1` |
| 3 | | `confirm_place_ok:19` `#button_count = 1` |
| 4 | B 藏匿超时 | `turn_timeout:17-18` 扣 B 1 分、`B.turn = 1` |
| 5 | `turn_advance`：已无人 `turn = 0` | → `enter_searching` |
| 6 | `enter_searching_classic:15`：`#button_count = 1` 命中 `..1` | → **直接 `end_round`** |

**B 本可以从 A 的按钮上取走那 1 分，这一步被跳过。**

**旁证（同一语义处用了另一个阈值）**：`game/searching_tick.mcfunction:12` 判收官用的是 `..0`：

```
execute if score #mode ybih.config matches 1 if score #button_count ybih.config matches ..0 run function ybih:game/end_round
```

按 `..0` 走，上例第 6 步会进入搜寻，B 取分后 `ybih.value` 归零 → `button/consume` → `#button_count = 0` → `searching_tick` 正常收官。

**性质**：确认是缺陷（纯静态可判）。影响 = 少打一轮搜寻、相关玩家少拿分；不卡死、不报错、无残留。

**建议修法**：把 `..1` 改为 `..0`（与 `searching_tick` 对齐），或在「场上按钮的分值全为 0」时跳过。

---

## 三、潜伏缺陷（当前不可达，但依赖隐含前提）

### P1 `leave_game` 不清棋类状态，可留下「幽灵对手」

**位置**：`src/data/ybih/function/player/leave_game.mcfunction`

该函数把 `ybih.id` 清零、摘掉 `ybih_player`，但**完全没有清理棋类状态**（`tstate` / `topp` / `rseat`）。

而 `room/ttt_tick` 的四条巡检守卫**全部要求 `tag=ybih_player`**：

```
execute at @e[tag=ybih_room,limit=1] as @a[tag=ybih_player,tag=!ybih_current,scores={ybih.tstate=1..},distance=..12] run function ybih:room/ttt_verify
execute at @e[tag=ybih_room,limit=1] as @a[tag=ybih_player,tag=!ybih_current,scores={ybih.tstate=1..2},distance=..12] run function ybih:room/ttt_notice
execute at @e[tag=ybih_room,limit=1] as @a[tag=ybih_player,scores={ybih.tstate=1..}] unless entity @s[distance=..12] run function ybih:room/ttt_abort
execute at @e[tag=ybih_room,limit=1] as @a[tag=ybih_player,scores={ybih.rseat=1..}] unless entity @s[distance=..12] run scoreboard players set @s ybih.rseat 0
```

**后果链**：摘掉 `ybih_player` 后巡检再也看不到他 → `tstate` 永久停在 3（对局中）→ 名单位被幽灵占着 → 对手一直等不到人。

**可达性分析**：`leave_game` 只由 `player/idle_state` 调用，而 `idle_state` 只在 `#state = 0`（对局外）触发：

```
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
```

下棋发生在 `#state = 2`，所以**正常流程下这条路径不可达** —— 棋局会先被 `cleanup_end` 里的 `room/ttt_reset` 清掉。

**但它依赖「阶段顺序不变」这个隐含前提**。一旦调整阶段流转顺序（或新增一个在 `#state=2` 里调 `leave_game` 的入口），立刻变成活跃 bug。

**建议修法**：在 `leave_game` 的清 id **之前**加一行 `function ybih:room/ttt_abort`。

> **为什么必须放在清 id 之前**：`ttt_abort` 靠 `@s ybih.id` 找回对手（`scoreboard players operation #me ybih.ttt = @s ybih.id`），id 一清零就找不到了。

---

## 四、轻微缺陷

### L1 非藏匿阶段点聊天栏按钮被静默吞掉

**位置**：`src/data/ybih/function/button/trigger_run.mcfunction:4, 33`

```
execute unless score #state ybih.config matches 2 run scoreboard players set @s ybih.trigger 0
…
execute if score #state ybih.config matches 2 if score #t_in ybih.ttt matches 0 if score @s ybih.trigger matches 11..52 run tellraw @s {{TXT_S}}棋桌在等待室里，轮到你藏的时候再去下{{TXT_M}}gray{{TXT_E}}
```

`11..52` 是棋类取值，**藏匿按钮用的 `1`（确认）与 `2`（取消重放）没有对应的兜底提示**。藏匿超时后再点【确认】，第 4 行把 trigger 清零、第 33 行条件不成立 ⇒ 这条点击不产生任何回执。

**性质**：体验问题，不影响计分与流程。

### L2 `ybih_presser` 是只减不增的死标签

**事实**：全库 3 处引用，**全部是 `remove`**，零 `add`：

```
game/cleanup_end.mcfunction:37      tag @a remove ybih_presser
game/reload_cleanup.mcfunction:38   tag @a remove ybih_presser
reset/run.mcfunction:52             tag @a remove ybih_presser
```

**对照**（都有明确 `add` 来源）：

| 标签 | 来源 |
|---|---|
| `ybih_button` | `register_here:5` 的 `summon` NBT |
| `ybih_ghost` | `consume:25` |
| `ybih_active` | `press_begin:16` |
| `ybih_new` | `register_here:5` 的 `summon` NBT（**注意**：用 `tag add` 搜不到，需按 `summon` 的 NBT 写法搜） |

**性质**：历史残留的死代码，运行期无行为。

### L3 `#hide_owed` 只能记一笔欠账

**位置**：`src/data/ybih/function/game/turn_timeout.mcfunction:23`

```
execute if score #hide_found ybih.config matches 0 run scoreboard players operation #hide_owed ybih.config = #hide_id ybih.config
```

`#hide_owed` 是**单个假玩家**。序列：

1. 藏匿者 A 超时且此刻不在线 → `#hide_owed = A 的编号`
2. A 尚未重连
3. 轮到 B，B 也超时且不在线 → `#hide_owed` 被写成 **B 的编号**，A 的欠账丢失
4. A 重连时 `player/on_join:16-18` 的编号比对不再命中 → A 不会被扣那 1 分

同文件注释显示作者已意识到「欠账必须是独立假玩家」：

```
# 必须是独立于 #hide_id 的假玩家，否则下一位藏匿者一上任就把欠账抹掉
```

但 `#hide_owed` 自身同样只能容纳一笔，连续两次「超时且掉线」即覆盖。

**性质**：确认是缺陷（逻辑可静态判定）。影响 = 个别玩家少扣 1 分，不影响玩法、不卡流程、无残留。

### L4 对局中的棋盘自带不带【离座】

**位置**：`src/data/ybih/function/room/ttt_board.mcfunction:101`（棋盘最后一行按钮排）

```
execute if score @s ybih.tres matches 1..3 run tellraw @s [{"text":"【再来一局】",...trigger set 32...},{"text":"  "},{"text":"【离座】",...trigger set 12...}]
```

带 `if score @s ybih.tres matches 1..3` 前置，只在**已分胜负**时才贴出 ⇒ 对局进行中（`tres=0`）棋盘上没有【离座】。

**功能不缺**：`ttt_status` 里 `tstate=3` 的 **13 行全部带【离座】**，棋子书里也有。只是棋盘自身不自带。

### L5 `trigger_run` 受理的点击值范围大于实际发出的范围

**位置**：`button/trigger_run.mcfunction:33`

提示分支用 `matches 11..52`，把从未发出的 `14..19`、`33..40` 也纳入。这些值无发出者、无分派，属**不可达路径**，当前无可观测影响。记录是因为区间式守卫在点击值表变动时不会自动收窄。

**实测的发出集合**：`{1, 2, 11, 12, 13, 20..28, 29, 30, 31, 32, 41..52}` —— 全部有分派，**无死键**。

### L6 `ttt_verify` 一处注释指向偏差

**位置**：`room/ttt_verify.mcfunction:28`

```
# 对不上就作废。正在被核对的人自己不在房里那种情况，由 ttt_tick 的另一条管
execute if score #tok ybih.ttt matches 0 run function ybih:room/ttt_abort
```

`ttt_tick:7` 调 `ttt_verify` 的前提本身就带 `distance=..12`，调用者一定在房里；那条兜底实际由 `ttt_tick` 独立完成，与 `ttt_verify` 无调用关系。**措辞偏差，行为无影响**。

### L7 `cleanup_all` 会清掉玩家背包里的按钮物品

**位置**：`src/data/ybih/function/util/cleanup_all.mcfunction:33`

```
clear @a #minecraft:buttons
```

作用于**玩家背包**（与方块无关）。地图作者预先发给玩家的按钮物品，会在 `/reload`、`/function ybih:reset`、`start_begin`（每局开局）、`cleanup_buttons`（每轮末）被一并清掉。

同族清理动作还有 3 处，作用对象同为玩家背包，但针对的是本包自己发出去的按钮，属机制必需：

```
player/give_buttons.mcfunction:11          clear @s #minecraft:buttons
button/confirm_place_ok.mcfunction:22      clear @s #minecraft:buttons
game/turn_timeout.mcfunction:25            execute as @a[tag=ybih_current] run clear @s #minecraft:buttons
```

`cleanup_all:33` 是唯一**全服、全量**的一处。

**性质**：文档与实现的口径差异（见 D2）。**未找到实际受害路径**（需地图作者主动给玩家发放按钮物品），故列轻微。

---

## 五、文档与实现不一致

### D1 `ybih_memory.md` 第十七节的 `enable` 数量已过时

`ybih_memory.md` 第十七节「待实测」第 1 条写：

> 全库只有两处 `enable`（`button/offer_confirm`、`button/redo_do`）……表现为**两个聊天按钮失效、且这次点击无任何反馈**，直到该玩家下次藏匿才恢复

**实测**：全库共 **5 处**：

| 位置 | 性质 |
|---|---|
| `button/offer_confirm.mcfunction:4` | 有条件的重开点 |
| `button/redo_do.mcfunction:7` | 有条件的重开点 |
| **`button/trigger_run.mcfunction:36`** | **无条件兜底**（每次触发后同 tick 重开） |
| `room/enter.mcfunction:16` | 进房时重开 |
| `room/enter_reopen.mcfunction:6` | 换人时对房内人重开 |

`trigger_run` 由 `tick.mcfunction:20` 每 tick 对 `@a[scores={ybih.trigger=1..}]` 调用，因此**每次成功触发后通道都会在同 tick 内被重新打开**。该条的「已知范围」需按当前代码重述；「这次点击无任何反馈」这一半仍然成立（即 L1）。

### D2 `README.md` 关于「地图自带按钮」的口径与实现不符

`README.md:308`：

> **地图自带的按钮不会被本数据包管理**：地图原有按钮既不计分、也不参与判定，**本数据包也不会去动它们**。

**事实**：`clear @a #minecraft:buttons` 作用于玩家背包，会清掉地图作者发给玩家的按钮物品（见 L7）。README 说的「按钮」指方块、实现动的是物品 —— 口径需澄清。

---

## 六、工程隐患

### E1 CI 的新鲜度检查漏了 `tools/`（**已实验复现**）

**位置**：`tools/verify_zips.py:37-49, 78`

```python
SRC = os.path.join(ROOT, "src")
def newest_source():
    for dirpath, _dirnames, filenames in os.walk(SRC):
```

但**所有生成器都在 `tools/`**（`build.mjs` 是新的大头，`ttt.mjs` 生成全部棋类函数）。改了生成器却不重新构建，这个校验会照样放行。

**复现**（本次审计实测）：只改 `tools/ttt.mjs` 的修改时间、不碰 `src/`，`python tools/verify_zips.py` 返回**退出码 0** 并打印「全部通过。」—— 而产物其实是旧的。

**建议修法**：把 `tools/` 一并纳入新鲜度比对。

### E2 `ybih.t_first` 与 `ybih.tfirst` 只差一个下划线

两者语义**完全不同**，极易混淆：

| 记分项 | 含义 | 使用处 |
|---|---|---|
| `ybih.t_first` | 藏匿顺序（原有序号，初值 999999） | `award_score`、`rank_scan`、`rank_take`、`turn_*`、`reset/run` 等 |
| `ybih.tfirst` | 九宫格棋的**这一局由执什么棋子的人先走** | `ttt_start`、`ttt_accept`、`ttt_abort`、`ttt_reset` |

两者都在实际使用、各自独立，功能上无互相干扰（已逐处核对）。但未来改动时极易写错。

**建议修法**：把棋类那个改名为 `ybih.ttt_first`（与其它棋类记分项 `ttt*` 命名一致）。需连带改 `tools/ttt.mjs`、`load.mcfunction` 与三份文档。

### E3 棋类分派缺少显式 `#state = 2` 守卫

**位置**：`button/trigger_run.mcfunction:16-29`

棋类的 11..52 分派行只判断「人在不在房里」：

```
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 11 run function ybih:room/ttt_refresh
```

**没有**独立的 `#state = 2` 判断，靠文件第一行间接兜住：

```
execute unless score #state ybih.config matches 2 run scoreboard players set @s ybih.trigger 0
```

**逻辑推演（当前安全）**：设 `#state = 3` 且玩家 `trigger = 12`：
1. 第 1 行：`#state ≠ 2` → trigger 被清零
2. 第 6 行：要求 `trigger matches 12` → 此时已是 0 → 不执行 ✅
3. 末尾提示行：要求 `#state matches 2` → 不执行 ✅

结论：**当前不会出错**，但正确性依赖「第 1 行一定先执行且一定清零」。建议补显式守卫，让每条分派自洽。

### E4 `ttt_abort` 在 `#topp` / `#me` 为 0 时的匹配面

**位置**：`room/ttt_abort.mcfunction:8, 31-47`

用 `if score @s ybih.id = #topp ybih.ttt` 找对手。若 `#topp = 0`，而场上有多个 `ybih.id` 也是 0 的玩家（`cleanup_end`、`run.mcfunction`、`start_begin`、`leave_game` 都会把 id 清零），这条会一次性匹配到**所有 id=0 的人**。

**未找到可达路径的原因**：第 31-47 行还额外要求对方的 `topp = #me`，需要「双向都是 0」才成立；而进入 `ttt_abort` 的调用点大多带 `tstate=1..` 守卫（`ttt_tick`、`turn/gather`），此时 `topp` 已被写过真实编号。

唯一无守卫的调用点是 `player/join_game:16`，但该文件第 4 行刚给玩家分配了新 id（≥1），所以 `#me ≥ 1`，安全。

**建议修法**：加一条 `#topp ybih.ttt matches 1..` 守卫，把「不可能」变成「不可能且显然」。

---

## 七、已排除的怀疑（别再重复查）

| 编号 | 曾经的怀疑 | 查证结果 |
|---|---|---|
| X1 | `#minecraft:buttons` 在 1.20 起不再覆盖石质按钮，10 处命令受影响 | **不成立**。23w16a 移除的是 `stone_button`/`polished_blackstone_button` 两个**具体条目**，换入等价的 `#stone_buttons` **子标签**，`#buttons` 的**传递闭包不变**。Wiki 的 block tag 列表同时存在 `buttons`、`stone_buttons`、`wooden_buttons` 三个条目。全区间 1.16.2–26.2 成立 |
| X2 | `config/set_center_here` 换集合点会泄漏区块强加载 | **不成立**。该函数末尾自己 `forceload add ~ ~`，同格重设时净效果正常 |
| X3 | `reload_cleanup` 漏调 `bar_hide` 导致 Boss 栏残留 | **不成立**。`load.mcfunction:75` 紧随其后调 `bar_init`（先 `remove` 后 `add`），`/reload` 路径不漏 |
| X4 | tellraw / title / actionbar 文本过宽会被截断 | **不成立**。tellraw 会**自动折行**（100px 上限只约束书页）；title 最宽 88px，GUI scale 3 下屏幕逻辑宽 640px，放得下（[Commands/title](https://minecraft.wiki/w/Commands/title)：屏幕标题过宽时不折行，只溢出） |
| X5 | 非藏匿阶段点棋类按钮会隔空落子 | **不成立**。第一行「非 2 就清零 trigger」已挡住（见 E3） |
| X6 | `press_begin` 的 2 tick 归属窗口会被跨阶段重置破坏 | **不成立**。`#tick` 只在 `#state 1..3` 递增，`#state` 由 3 变 2 只发生在会归零 `#tick` 的路径上 |
| X7 | `cleanup_end` 少清一部分玩家记分项是漏写 | **不成立**。有意保留分数供查看，`start_begin:16-23` 在下一局开局补清 |
| X8 | `#button_count` 会被减成负数、导致搜寻阶段开局即判「已按完」 | **不成立**。`consume:14` 与 `give_up:9` 都带 `matches 1..` 守卫 |

---

## 八、待实测项

静态审计无法定论，需真实客户端/服务器。

| 编号 | 现象 | 位置 | 为什么必须实测 |
|---|---|---|---|
| T1 | **点击通道 `enable` 状态是否跨重连保留** | `button/trigger_run:36`、`tick.mcfunction:20` | `trigger_run` 只在 `trigger` 非零时被调用。玩家在通道关闭后掉线、重连且期间无换人事件，就没人替他重开。取决于原版对 `trigger` 启用状态的持久化行为 |
| T2 | 双人同时掉线后重连的恢复 | `ttt_verify:27`、`room/second_tick:9` | 推演应能各自恢复；但若两人**同一秒内**先后上线，是否出现互相作废、提示重复/错位，需实测 |
| T3 | 邀请提示是否自动出现 | `room/ttt_notice` | 曾因漏逗号整份文件不加载而静默失效，已修并加构建期校验。对应验收单 F33b6 |
| T4 | 多局并行互不干扰 | 棋类全体 | 需 4 人两客户端验证 A 局落子不影响 B 局。对应验收单 F33b2 |
| T5 | 【再来一局】能否连开且换先手 | `ttt_again`、`ttt_click:52` | 依赖「下完切 `tstate=4`」。对应验收单 F33b3 |
| T6 | 被拎去藏时对手是否立刻收到作废 | `turn/gather:8` | 需真机验证即时清理。对应验收单 F33b5 |
| T7 | 围观中途 `/reload` 的方块清扫顺序 | `util/cleanup_all:13,17,21,23-31` | 顺序只在代码层推演过。对应验收单 E12/E13 |
| T8 | 满背包时的溢出提示 | `player/give_buttons:50-63` | 依赖 `@e[type=item,...nbt={Item:{id:...}}]`，只做过构建期校验；反向验证（正常背包不应提示）同样未做 |
| T9 | 两遍射线（`ray_loop`/`ray_loop_nbr` 等） | `button/ray_loop_nbr:21`、`use_ray_nbr:14` | 几何复现覆盖 1440 场景、召回 100%，但没进游戏跑过。风险点是第二遍的门用 `unless block ~ ~ ~ air`/`cave_air`/`void_air`，若某版本名字有出入会整行解析失败 |
| T10 | `ybih.id ≥ 31` 与 `sort=nearest` 等距并列 | `press_begin:25`、`register_ok:9,13,14,18,19,33` | 超出 30 位位图宽度；等距时取谁未实测。超 30 人不在设计目标内 |
| T11 | 三包在各自版本区间的实际加载 | `dist/*.zip` | 静态只能保证语法与目录名正确。包 3 已在 1.21.11 实测通过，其余版本未覆盖 |

**已降级为可选**：贴边判定的中间量溢出（`button/border_edge_check:29-38`）—— 静态推演已证明 `#lim` 最大 29999983、`#dx`/`#dz` 先 `/= #c100` 再比，**没有任何取值能触发 int32 回绕**，实机复核从「必要」降为「可选」。

**已论证当前不可达**：`game/turn_timeout_mode2` 绕过 `end_round:3` 的状态守卫 —— 调用方要求 `#state=2`，而守卫是 `#state matches 3`，藏匿阶段谁都按不了按钮。若日后 `turn_timeout`/`second_tick` 执行顺序变化会退化。

---

## 九、确认无误的覆盖清单

这一节记录**已查过、确认正确**的项，以免日后重复怀疑。

### 9.1 版本适配

| 检查项 | 结果 |
|---|---|
| `pack.mcmeta` | 6 / 41 / 71，各自对应区间下限；包 3 另有 `min_format [71,0]` / `max_format [107,1]`，与声称的 1.21.5–26.2 一致 |
| 目录名 | 包 1 复数（`advancements`/`function`+`functions`/`tags`）、包 2 单复数并存、包 3 仅单数，与 `manifest.mjs` 的标志一致 |
| 进度触发器 | 放置 `placed_block`（三包一致）；交互 包 1 `item_used_on_block`、包 2/3 `any_block_use` |
| 进度 `location` | 包 1 双份（谓词数组 + `_legacy` 裸对象）；包 2/3 已由 `skipFiles` 摘除全部 `legacy` 文件（**实测产物中不存在**） |
| 方块谓词字段 | 包 1 `{"tag":"minecraft:buttons"}`；包 2/3 `{"blocks":"#minecraft:buttons"}` |
| 物品 NBT/组件 | 包 1 `{CanPlaceOn:["#ybih:placeable_surfaces"],HideFlags:16}`；包 2 `can_place_on={predicates:[...]}` + `hide_additional_tooltip`；包 3 `can_place_on={blocks:...}` + `tooltip_display` |
| 文本方言 | 包 1/2 JSON、包 3 SNBT，**零交叉污染**（`can_place_on` 在包 2 出现 0 处、`predicates` 在包 3 出现 0 处，各自正确） |
| 书籍格式 | 三套各用对：`written_book{pages:[...]}` / `[minecraft:written_book_content={...}]` / SNBT 裸对象 |
| `hover` / `change_page` | 三套自洽，且与包内已在游戏中验证过的 `admin/book.mcfunction` 写法一致 |
| 高版本语法泄漏 | 包 1 中 `run return`/`if items`/`if loaded`/`data modify`/SNBT 裸对象 **均 0 处** |
| 等待室高度 | 245 / 300 / 300，与 `manifest.mjs` 的 `waitRoomY` 一致 |

### 9.2 棋类核心逻辑

| 检查项 | 结果 |
|---|---|
| 判胜 vs 平局优先级 | 判胜（8 条线）在前、平局在后，都带 `tres matches 0` 守卫 ⇒ 第 9 手成三子正确判胜，不被平局覆盖 |
| 胜方值语义 | `tres` 直接存胜方棋子值（1/2），与 `trole` 对应 |
| 开局对称性 | `ttt_start` 自己侧 20 条写入与对手侧 20 条**一一对应**，无缺项 |
| 先手翻转时机 | 排在「读先手」之后，本局用的是本局的值 |
| 状态机完整性 | `tstate` 五态全部转移路径与出口齐备；`ttt_abort` 覆盖 1/2/3/4 全态 |
| 并发安全 | 37 个 `#` 假名的传递写集合与调用图逐条比对，**不存在「读到自己没写的值」**；唯一例外是 `#t_quiet`（即 M1） |
| 单线程语义 | `execute as @a[...] run function` 逐个跑完才轮到下一位，两局不交错 —— 这是「棋盘跟着人走」能支持无限局数的机理 |
| 棋盘等宽 | 81 行**全部 81px** |
| 棋盘标签↔触发值 | 81 处「显示 `【１】..【９】` ↔ `trigger = 19 + 格号`」机械校验，**0 错配** |
| 棋盘组合覆盖 | 每行 **27/27 全覆盖**；三格全占的 8 种无点击事件（正确，无空格可点） |
| 槽位常量一致性 | `ttt_roster`（60 行）、`ttt_status`（56 行）、`ttt_notice`（34 行）逐行校验「槽位常量 ↔ 选择器」**0 错配**；`ttt_invite_2..12` 与 `invite_1` **完全同构** |
| 书页宽度 | 两页最宽行 81px / 90px，均在 100px 限内 |
| 书页按钮与分派 | 书里发 11/12/13，`trigger_run` **均有对应分派** |
| `ttt_reset` 完整性 | **双向差集为空**：37 个被写入的假名全部被清零，无「清零但无人写入」的多余项；玩家侧 12 个记分项全覆盖 |
| `ttt_reset` 调用点 | 恰好 5 处，与 checklist 完全吻合：`reload_cleanup:58`、`start_begin:6`、`cleanup_end:53`、`enter_searching_run:5`、`reset/run:45` |
| 边界：单人 | 自邀被挡、名单把自己剔除，看名单为空 |
| 边界：12 位满员 | `ttt_seat:47` 有明确提示「等待室名单满了（12 位），先看别人下」，不静默 |
| 边界：对手掉线 | 在线一方由 `ttt_tick:7` → `ttt_verify:27` 判作废并收到提示；`ttt_tick:4` 每秒归零 `#t_quiet`，此路径**不被抑制** |
| 边界：对手被传送出房 | `ttt_tick:12` 兜底作废 |
| 边界：开局瞬间被拎走 | `turn/gather:8` 立刻调 `ttt_abort`，且只对 `tstate=1..` 的人调用以免给空闲者误发提示 |
| 与非棋系统隔离 | `room/info`、`info_one`、`sparkle`、`enter_reopen` 检索棋类记分项 **0 命中**；`room` 下无 `rps_*` 残留 |
| 「在房里」判定 | `#t_in` 先归零再置位，房间标记缺失时保持 0，不会误判；阈值 `12` 在各处一致；房间内空 11×11×3，最远角落约 7.7 格，覆盖充分 |

### 9.3 核心流程

| 检查项 | 结果 |
|---|---|
| 状态机 | `#state` 全部取值 0..4 的进入点与出口；`player/on_join` 三分支（`1..3`→`active_state`、`4`→`showcase_state`、`0`→`idle_state`）覆盖全部取值 |
| 围观阶段 | `showcase_step` 与 `showcase_pick` 互斥，`showcase_end` 只调一次 |
| 记分板 | `ybih.value = #player_count − 1` 与「除物主外人人可取一份」严格对应，取满归零 |
| 位图去重 | `#hit_bit 536870912`、`#hit_pow 1073741824` 均在 int32 内；`id ≥ 31` 由 `#deny 1` 兜住 |
| `#online_sum` / `#online_now` | `#next_id` 每局归零，**不可能溢出** |
| 侧边栏离线清行 | `reset * ybih.board` 是唯一能触到离线玩家的写法；另有 `#board_gc` 10 秒无条件重建兜底 |
| `scoreboard players reset *` | 全库**一律带记分板名**，裸 `reset *`（会清掉全服 `trigger` 权限）**不存在** |
| 进度 `rewards.function` | 引用目标全部存在；包 2/3 不引用已摘除的 `on_use_legacy` |
| 进度 revoke | `on_place:5`、`on_use:23`、`on_use_legacy:11` 各撤自己那一份，不互撤 |
| `forceload` | 申请 4 处、释放 4 处**一一对应**，且**每处 `kill` 之前都先 `forceload remove`** |
| `util/remove_wait_room` | 两条 `fill` 顺序（先 `~..~8` 后 `~-1..~-1`）符合「先上后下」约定，避免地毯崩落 |
| 游戏模式还原 | 五个还原点写法同构；`showcase_end` 有意不摘 `ybih_gm_*`（摘了会让第二轮参与者卡在旁观） |
| 「至多一个 `ybih_gm_*`」 | `join_game:22-27`、`spectate:20-25`、`showcase_state:12-17` 都先无条件 `remove` 三个再 `add` 一个 |
| 标签凭据 | 全部逐个核对增删配对；实体类走 `util/cleanup_all` 的 `kill`，玩家类走 `cleanup_end`/`reload_cleanup`/`reset/run`/`restore_gamemode` |
| `ybih_ttt_booked` | 全项目**只有 `ttt_book:7-8` 两处写入、无任何 remove** —— 「反复进出不越攒越多」与「丢弃后不再补发」同时成立，且注释说明是有意保留 |
| 按钮全被水冲毁 | 有出口（`give_up` 收回 + 计数守卫） |
| `clear_placed_blocks` / `ybih_wait` | 都只被 `cleanup_all` 引用，是旧存档兼容路径，仍在线，非死代码 |

### 9.4 文本与排版

度量口径（项目自订）：**中文全角 9px、半角 6px、空格 4px**。

| 命令族 | 条数 | 最宽 | 结论 |
|---|---|---|---|
| `tellraw`（会折行） | 43 | 453px（`load:78` 的设置书提示） | 共 30 条超 100px。**聊天栏自动折行**，100px 上限只约束书页，**不构成缺陷** |
| `title`（不折行） | 6 | 88px（`next_round:27`、`start_begin:64` 的「第 N / M 轮」） | GUI scale 3 下屏幕逻辑宽 640px，**放得下** |
| `actionbar` | 6 | 360px（`room/info_one:12`，按玩家名 16 字符取上界） | **放得下**；未覆盖 GUI scale 1 的极端设置（记为余量） |
| `bossbar name` | 7 | 344px（`showcase_bar_owner:8`） | Wiki 未说明超宽行为，**未找到缺陷证据**，不列入结论 |

---

## 十、修复优先级建议

| 优先级 | 编号 | 理由 | 改动量 |
|---|---|---|---|
| 1 | **M1** | 当前可达，后果是「对手彻底静默、只能自己想起来点刷新」 | 对齐 3 个入口的 `#t_quiet` 处理 |
| 2 | **M3** | 当前可达，**直接吞掉应得的分数**；修法是一字之差（`..1` → `..0`） | 1 行 |
| 3 | **M2** | 当前可达，会让某人在名单上消失；需设计离线占用感知 | 中等 |
| 4 | **E1** | 影响对「构建是否新鲜」的信任 | 改一个遍历目录 |
| 5 | **P1** | 潜伏缺陷，修复成本极低 | 加 1 行 |
| 6 | L1 / L2 / L3 | 体验与小瑕疵 | 小 |
| 7 | E3 / E4 | 消除隐式依赖 | 机械改动 |
| 8 | D1 / D2 | 文档对齐代码 | 改文档 |
| 9 | E2 | 收益明确但要连带改生成器与三份文档 | 建议单独一次提交 |

---

## 十一、审计方法与本次自身的误判记录

### 方法

- **构建与产物**：`node tools/build.mjs` + `python tools/verify_zips.py` 各自跑通（退出码 0）；在 `%TEMP%` 副本中重构建，与仓库 `dist/` 逐项比对
- **产物优先**：所有命令级结论**一律以解压后的 zip 为准**，不以生成器源码为准；并已逐字节确认两者一致（仅差构建期模板占位符的渲染）
- **机械校验**（非目测）：假名写入集合 vs 清零集合的双向差集；棋盘 81 处标签↔触发值映射；三份逐位写死文件的槽位常量一致性；12 份 `ttt_invite_*` 的同构性；点击值「发出 ↔ 分派」的覆盖比对
- **逻辑推演**：对每条可疑路径构造具体数值场景逐步推演（如 M3 用 2 人局 6 步、E3 用 `#state=3, trigger=12`）
- **外部依据**：原版标签成员与命令行为引 Minecraft Wiki 原文（[Block tag (Java Edition)](https://minecraft.wiki/w/Block_tag_(Java_Edition))、[Java Edition 23w16a](https://minecraft.wiki/w/Java_Edition_23w16a)、[Commands/title](https://minecraft.wiki/w/Commands/title)），不凭记忆
- **回归测试**：本轮新加的构建期校验都用「把 bug 改回去」的方式验证过确实能拦

### 本次审计中犯过的错（记录以免后人重蹈）

1. **漏检 M1（最重要的一条）**：主审计按 `ttt_leave` 自己写的注释（「免得同一件事提示两遍」）理解了 `#t_quiet` 的意图，**没有去核实那句 tellraw 的收件人**。实际 `as @a` 把 `@s` 换成了对手，抑制掉的是对手唯一的通知。该条由专项审计发现，主审计已逐条复核确认。**教训：注释与实现不一致时，以命令的实际执行上下文为准。**
2. **凭据标签统计误报**：初版正则只认 `tag @s add X`，漏了 `summon` 的 NBT 写法与 `kill @e[tag=X]`，一度把 `ybih_ghost`/`ybih_button`/`ybih_new` 误判为「只加不删」。三项实际都配对完整。
3. **`ybih_placed` 假输入**：把它当成标签统计，实际源码里**根本没有这个标签**（是记分项 `ybih.placed`）。
4. **`#minecraft:buttons` 曾误判**：据 23w16a 的「移除」字样推断 1.20+ 不再覆盖石质按钮，进而认为 10 处命令受影响；查证后推翻（见 X1）。
5. **文本宽度分类错误**：初版脚本把 `title @a actionbar` 误归 `title` 族，使 actionbar 被当成「大标题溢出」；修正分类后结论改变。
6. **子代理状态误判**：最初派的后台审计子代理不在 `list_agents`（那是 teammates 列表），主审计误以为它们已丢失并重复派了两个。实际它们仍在运行并最终交付，其中一条结论纠正了主审计的漏检（见第 1 条）。

---

## 十二、本次审计未覆盖的部分

- **运行时行为**：所有结论均为静态分析，未在真实服务器/客户端运行（第八节已列待实测项）
- **性能**：只做了命令量估算（每秒巡检：`ttt_tick` 5 条 + 每人 `ttt_verify` 22 条 + `ttt_notice` 28 条），未做 TPS 实测
- **`tools/check_md.js`**：未纳入本次审计
- **`dist/` 产物的实际游戏加载**：见 T11
- **地图作者侧行为**：如 L7 的「地图作者主动发放按钮物品」这一前提未验证

---

*本报告为最终版，已合并三份专项审计（主审计 + 九宫格棋子系统 + 核心游戏流程）的全部结论，所有条目均经主审计复核或明确标注来源。*

---

## 十三、修复记录（审计后处理）

上表 **16 条全部已修**（M1 M2 M3 P1、L1–L7、D1 D2、E1–E4）。
三包重新构建退出码 0，`tools/verify_zips.py` 退出码 0，`tools/check_md.js` 退出码 0。

| 编号 | 改动落点 | 做法 |
|---|---|---|
| M1 | `tools/ttt.mjs`（`genTttExit` / `genTttAbort` / `ttt_invite` / `ttt_tick`） | **删掉 `#t_quiet` 整套机制**，不再有任何抑制；`abort` 里那句通知的收件人本就是对手，与调用方那句不重复 |
| M2 | `tools/ttt.mjs`（`genTttSeat` 重写、新增 `genTttRelease`、`genTttReset`）、`room/ttt_tick`、`player/join_game`、`turn/gather` | 占用表 `#rs1..#rs12` 改为**只增不减**，放位子只能走 `room/ttt_release`（`rseat` 与 `#rsN` 成对清）；`ttt_reset` 改用 `reset *`（唯一能清掉离线玩家的写法） |
| M3 | `game/enter_searching_classic` | `..1` → `..0`（与 `searching_tick` 对齐），三处提示同步改成 `1..` |
| P1 | `player/leave_game` | 在清 `ybih.id` **之前**调 `ybih:room/ttt_abort`（abort 靠编号找回对手，顺序不能反） |
| L1 | `button/trigger_run` | 非藏匿阶段点 1/2 补提示；**该条必须排在清零之前**，否则值已归零、判不出来 |
| L2 | `game/cleanup_end`、`game/reload_cleanup`、`reset/run` | 三处 `tag @a remove ybih_presser` 全部删除 |
| L3 | `game/turn_timeout`、`player/on_join`、新增 `game/owed_bit`、`config/defaults`、`load` | 单槽 `#hide_owed` 改为**位图**（挂在 `ybih.config` 上的假玩家 `#owed`，位号 = 编号 − 1，与 `ybih.hit` 同一套取模），按位或累加、按位减结清 |
| L4 | `tools/ttt.mjs`（`genTttBoard`） | 棋盘最后一行补一条 `unless tres 1..3` 分支，对局中也有【离座】；对局中仍**不给**【再来一局】（它认的是「刚下完」） |
| L5 | `button/trigger_run` | `11..52` 拆成 `11..13` / `20..32` / `41..52` 三段，不再覆盖无人发出的 `14..19`、`33..40` |
| L6 | `tools/ttt.mjs`（`genTttVerify`） | 注释改为说明「那条兜底由 `ttt_tick` 独立完成、与本函数无调用关系」 |
| L7 / D2 | `README.md` 已知限制 | 明确写出「玩家背包里的按钮物品会被清掉」（清的是物品，与管理按钮方块是两回事） |
| D1 | `ybih_memory.md` 第十七节 | 按实际 5 处 `enable` 重述，并说明 `trigger_run` 是无条件兜底、通道不会长期失效 |
| E1 | `tools/verify_zips.py` | 新鲜度检查纳入 `tools/`（生成器全在那儿）；已实验复现：单独 touch `tools/ttt.mjs` 现在会退出码 1 |
| E2 | `load.mcfunction`、`tools/ttt.mjs` | 棋类先手记分项改名 `ybih.tfirst` → **`ybih.ttt_first`**，并加注释说明与藏匿顺序 `ybih.t_first` 的区别 |
| E3 | `button/trigger_run` | 每条棋类分派补显式 `#state = 2`，不再依赖「第一行顺手清零」这一隐式前提 |
| E4 | `tools/ttt.mjs`（`genTttAbort`） | 加 `#has_opp` 守卫（`#topp` 必须 ≥ 1），避免「双方编号都是 0」时选中所有 id=0 的人 |

### 修复过程中新引入并当场修正的问题（记录以免重蹈）

1. **`button/trigger_run` 的 L1 提示排错位置**：兜底提示写在清零语句**之后**，`@s ybih.trigger` 已变 0，那条提示永远不会触发。已移到清零之前。
2. **`ttt_seat` 的「空位」判据**：`ttt_reset` 改用 `reset *` 后会**删掉条目**而不只是置 0，而 `matches 0` 对「没有条目」的记分板持有者**不成立** —— 满员提示与空位判定会一起失效。两处都改成 `unless ... matches 1..`，并在 `config/defaults` 里给 `#rs1..#rs12` 写初值。
3. **`scoreboard players remove` 不吃记分板源**：位图减法只能写 `operation ... -=`，不能写 `remove ... <源>`。

### 复检轮（对修复本身再做一次对抗性复查）新查出的问题

修复提交之后又完整复查了一遍修复产物（把修复前那一版也构建出来，逐条比对**会执行的命令**，
忽略注释与空行），查出下面 5 条。它们全都是**这次修复自己带进来的**，
前 4 条已当场改掉，第 5 条连同一条构建期守卫一起补上。

| # | 位置 | 问题 | 后果 |
| --- | --- | --- | --- |
| R1 | `game/turn_timeout` | 记账三行里，**累加那一行漏了 `#hide_found matches 0`**，且累加前没有先把 `#owed_bit` 归零 | `#owed_bit` 是每次结算复用的暂存。目标这次**在线**（已当场扣过分）时，会照着上一轮留下的旧掩码再累加一次；重复置同一位会让位图**进位** —— 该销账的没销，编号大一位的**无辜玩家**反而被扣一分 |
| R2 | `room/ttt_reset`（`tools/ttt.mjs`） | 改用 `reset *` 之后**只有它、没有补写 0** | `reset *` 删掉的是**条目本身**，而 `room/ttt_invite` 里有一句 `operation #myslot = @s rseat` —— 读一个不存在的条目会让这条命令**静默失败**、`#myslot` 保留上一个人的值，于是邀请会写到错误的号位上（聊天栏里显示出**别人的名字**） |
| R3 | `load.mcfunction` | 顺手声明了一个 `ybih.owed` 记分项，但超时欠账的位图**实际挂在 `ybih.config` 的假玩家 `#owed` 上** | 空记分项本身无害，但它会让人以为「欠账在 `ybih.owed` 里」，照着它去读永远读到空。已删除该声明，并修正 `game/turn_timeout`、`player/on_join`、`ybih_memory.md`、`ybih_design_doc.md` 里的相关措辞 |
| R4 | `tools/ttt.mjs` | `genTttStart` 里的注释还写着旧名 `tfirst` | 纯注释，但正是 E2 要消灭的那种「一低头就写回旧名」的隐患 |
| R5 | `tools/build.mjs` | — | 新增**构建期守卫**：`scoreboard objectives add` 声明的记分项必须真的被读写过，否则报错。已用反向对照验证（临时塞一个 `ybih.deadcheck` 进去，构建确实以退出码 1 失败）。查重按函数根目录分别进行 —— 低版本包有意同时提供 `functions/` 与 `function/` 两份 |

R1 另写了记分板语义的仿真脚本做验证（含反向对照：把修复去掉后，位图确实从 `2` 被污染成 `4`），
确认判据不是空转的；脚本属一次性排查工具，未留在仓库里。

键位记录：**`reset *` 是唯一能清掉离线玩家的写法，但它删条目而不是置 0**
—— 凡是读 `ybih.rseat` 的地方，判据一律得是 `unless ... matches 1..`，
且每个 `reset *` 之后都要给在线者补一个 `0`。这是本轮风险最高的一处。

### 仍需实机验证

本报告第八节的 T1–T11 仍全部有效（静态分析不能替代实机）。
此外本轮修复新增的实机项已并入 `ybih_test_checklist.txt`：`F5b`（M3）、`F5c`（L3）、`F33b9`（M1）、`F33b10`（M2）、`F33b11`（L4）、`F33b12`（L1）。
复检轮新查出并修掉的 R1 / R2 / R3 也各补了一条用例：`F5d`（R1 连续两次超时、其中一次人在线）、
`F33b13`（R2 邀请时报出的名字必须是本人）、`F5e`（R3 欠账位图落在 `#owed` 上）。
