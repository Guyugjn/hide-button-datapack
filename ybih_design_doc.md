# 《你的按钮我来藏》数据包设计文档

> 适用 Minecraft Java 版 1.16 – 26.2，命名空间 `ybih`。

---

## 一、概述

多人捉迷藏小游戏。开局每人获得全套按钮各一个，但**只能藏一个**；藏匿期轮流进行，
结束后进入搜寻期，玩家去**按下**别人的按钮得分。全场按钮被找完即结束，按分数排名。

两种模式，用设置书切换：

- **经典 · 各藏各找**：每人轮流藏一个按钮，藏完一起找；按下别人的按钮得分，按得越早分越高。
- **轮流 · 一人藏众人找**：一轮只有一人藏，其余人抢着找；第一个找到的人分最高，
  藏匿者拿走没人找到的那一份；每个周期每人各藏一次。

核心原则：

- 只认注册标记，不认按钮方块。
- 玩家用 `ybih.id` 标识，按钮标记用 `ybih.owner_id` 记录物主。
- 统一使用 `armor_stand{Marker:1b}` 作为标记实体，全版本可用。
  （不换 `marker` 实体：它 1.17 才有，且**不能接受状态效果**，而围观高亮靠给标记挂 `glowing`。）
- 版本差异通过**分包**处理，不做运行时版本探测。
- 完全不使用 `gamerule`，避开 1.21.11 的游戏规则改名。
- 以玩家为中心扫描，按秒节流显示，保护检测按 tick 间隔节流。
  每 tick 的固定遍历只有两处（按下检测每 tick、保护每 5 tick），
  都带 `type=armor_stand`，只遍历盔甲架而不是全部实体。
  **新增逐实体逻辑时走「一次遍历 + 内部廉价分派」**，不要按材质/朝向各扫一遍。
- 计分一律采用**余量分**（按下时场上还剩多少份），两种模式共用一套口径。
- 放下按钮后默认要在聊天栏点【确认】才生效，放错可以【取消重放】。
- reload 清对局、留设置：`/reload` 清空对局数据与场上按钮、拆掉高空等待室，但保留书里改过的设置和集合点。
- 一局可含多轮，每轮一次完整的「藏匿 + 搜寻」，分数跨轮累计。

---

## 二、玩法定稿

| 项 | 规则 |
|---|---|
| 模式 | `#mode` 1 经典（默认）/ 2 轮流；对局进行中不能切换 |
| 每人按钮数 | **轮到谁才发给谁**全套按钮各 1 个，**只能藏 1 个**，确认后其余立即清空 |
| 藏匿方式 | 经典模式每轮所有参与者按 `ybih.id` 升序轮流藏；轮流模式每轮只有一人藏 |
| 等待的人 | 送进集合点正上方的密闭等待室 |
| 换人条件 | 确认藏匿立即换下一位；或每人限时（默认 60 秒）超时，本回合作废并**扣 1 分** |
| 放置确认 | `#confirm` 1 开启（默认）：放下后聊天栏出现【确认】与【取消重放】，不确认不生效；2 关闭：放下即生效 |
| 放错处理 | 点【取消重放】退回材质并收回按钮；再放一个按钮也会自动退回上一个 |
| 物主被按 | 不淘汰、不扣分，继续参与 |
| 计分（经典） | 按下别人的按钮 += 按下瞬间场上剩余按钮数（含这个）；每轮结束按钮没被找到 +1；藏匿超时 −1 |
| 计分（轮流） | 找到者 += 找到瞬间还没找到的搜寻者数（含自己）；轮末藏匿者 += 剩下的没被找到人数；藏匿超时 −1 |
| 排名 | 分数 → 发现次数 → 首次发现时刻 → `ybih.id`，严格全序，名次不会并列（分数本身可能并列） |
| 按自己的按钮 | 不得分，按钮保留 |
| 重复放置防护 | 只有当前轮次、且本回合还没藏过的人，放置才会被注册 |
| 结束（经典） | 全场按钮被找完立即结束本轮；搜寻倒计时（默认 600 秒）兜底 |
| 结束（轮流） | 所有搜寻者都找到、或搜寻倒计时到点结束本轮 |
| 藏匿者去向（轮流） | 搜寻阶段转旁观模式观战，轮末传送回集合点再切回冒险模式 |
| 局制 | 一局若干轮，每轮一次完整的「藏匿 + 搜寻」，分数跨轮累计；轮数用完自动总结并结束 |
| 参与人数 | 只有 1 人时给提示但照常开局（单人可用于试流程） |
| 提示 | 每 60 秒告知玩家「半径 N 格内有没有别人的按钮」，只给有/无；间隔与半径都可调 |
| 饥饿与伤害 | 开局起常驻抗性提升 V + 饱和 V，饿不着也打不掉血，挂到下一次 /reload 为止 |
| 按钮外观 | 真实按钮方块，无显示实体 |
| 按钮保护 | 定期检测，方块丢失则按原材质与原朝向恢复 |

---

## 三、版本与分包

数据包按版本切成 3 份，各自 `pack.mcmeta` 独立，由 `tools/build.mjs` 从 `src/` 单一源生成。

| 包 | 覆盖版本 | pack 元数据 | 按钮数 |
|---|---|---|---|
| 1 | 1.16.2 – 1.20.4 | `pack_format` 6 + `supported_formats` [6,26] | 10 |
| 2 | 1.20.5 – 1.21.4 | `pack_format` 41 + `supported_formats` [41,61] | 13 |
| 3 | 1.21.5 – 26.2 | `pack_format` 71 + `supported_formats` [71,107] + `min_format` [71,0] + `max_format` [107,1] | 14 |

按钮清单（按加入版本递增）：

- 基础 10 种：橡木、云杉、白桦、丛林、金合欢、深色橡木、绯红、诡异、石头、磨制黑石
- 1.19 起 +红树 → 11
- 1.20 起 +竹、樱花 → 13
- 1.21.4 起 +苍白橡木 → 14

各包取覆盖区间下限的清单：包 1 用 10 种，包 2 用 13 种，包 3 用 14 种。
（杨树按钮在 26.3 才加入，超出范围。）

---

## 四、记分板与常量

| 记分板 | 用途 |
|---|---|
| `ybih.config` | 全局状态与配置 |
| `ybih.id` | 玩家唯一 ID |
| `ybih.score` | 分数（真实成绩，跨离线保留） |
| `ybih.board` | 侧边栏显示的镜像榜，只写当前在线的玩家 |
| `ybih.placed` | 是否已确认藏好按钮 |
| `ybih.turn` | 本轮（经典）或本周期（轮流）是否已藏过 |
| `ybih.owner_id` | 按钮物主 ID |
| `ybih.death` | `deathCount` 类型，用于死亡后补回冒险模式 |
| `ybih.finds` | 本局找到按钮的次数，排名次用 |
| `ybih.t_first` | 本局首次找到按钮的全局 tick，排名次用 |
| `ybih.found` | 轮流模式：本轮是否已经找到 |
| `ybih.used` | 玩家最近一次「对着按钮交互」的全局 tick，判定按下者用（初始 −1） |
| `ybih.bid` | 按钮标记的编号，由 `#bid` 发放；按下判定靠它与玩家比对 |
| `ybih.used_bid` | 玩家最近一次交互的那个按钮的编号，由 `on_use` 的射线锁定 |
| `ybih.fixed` | 按钮被保护机制恢复过几次，到上限就收回（见第八节） |
| `ybih.era` | 按钮标记所属的局编号，用来隔开上一局遗留在未加载区块里的按钮 |
| `ybih.trigger` | `trigger` 准则，聊天栏点击提交确认/重放 |

`ybih.trigger` 必须是 `trigger` 准则（不是 `dummy`），否则 `/trigger` 命令直接失败；
普通玩家即使没有 OP 也能用 `/trigger`，这是聊天栏按钮能在冒险模式下工作的原因。

`ybih.config` 上的常量：

| 常量 | 含义 |
|---|---|
| `#state` | 0 空闲 / 1 准备 / 2 轮流藏匿 / 3 搜寻 / 4 轮末围观 |
| `#mode` | 游戏模式：1 经典 / 2 轮流 |
| `#confirm` | 放错确认：1 开启 / 2 关闭 |
| `#timer` | 准备与搜寻阶段的剩余秒数 |
| `#hide_timer` | 当前藏匿者剩余秒数 |
| `#actionbar_timer` | 每秒逻辑节流，归零触发 `game/second_tick` |
| `#hint_timer` | 冷热提示计时 |
| `#protect_timer` | 按钮保护检测计时 |
| `#board_timer` / `#board_gc` | 侧边栏镜像榜的名单比对节流 / 兜底重建周期 |
| `#buff_timer` | 对局保险的每秒重发节流 |
| `#online_prev` `#online_sum` `#online_sum_prev` | 「有人进出」快照：上次在线人数、本次在场 id 之和、上次的 id 之和 |
| `#show_idx` `#show_total` | 围观展示：当前看到第几个、本轮总数 |
| `#show_found` `#showcase_on` | 围观展示的按钮当时有没有被找到 / 围观开关 |
| `#show_len` / `#show_timer` / `#show_sec` / `#show_refresh` | 每个按钮停留多少 tick、这一个的剩余 tick、剩余秒数、标题刷新倒计时 |
| `#fix_owner` | 收回保不住的按钮时暂存物主编号 |
| `#wet` | 放置校验：按钮的四个水平邻格与正上方是不是有水或岩浆（正下方不算，水不向上流） |
| `#tick` | 全局 tick 计数（对局中自增），记首次发现时刻 |
| `#next_id` | 下一个玩家 ID |
| `#best` | 选人用的临时最小值 |
| `#best_score` `#best_finds` `#best_tfirst` `#best_id` | 排名扫描用的当前最优值 |
| `#ranked` | 已排出名次的人数 |
| `#ray_step` / `#ray_owner` | 放置射线临时值 |
| `#era` | 本局编号，跨 `/reload` 保持递增；用来把上一局遗留在未加载区块里的按钮标记隔开 |
| `#bid` | 按钮编号计数器，与 `#era` 同待遇、跨 `/reload` 保持递增 |
| `#use_min` | 按下判定的时间窗下限（`#tick - 2`），只用来挡掉陈旧的交互记录 |
| `#press_owner` | 当前被按按钮的物主 |
| `#press_bid` | 当前被按按钮的编号，与玩家的 `ybih.used_bid` 比对 |
| `#use_bid` | 射线锁定按钮时暂存读到的编号 |
| `#hint_self` / `#hint_hit` | 冷热提示临时值 |
| `#gained` | 本次得分，用于播报 |
| `#survive_hit` / `#survive_self` | 存活加分扫描：本次是否命中没被找到的按钮、正在比对的物主编号 |
| `#found_seq` / `#seekers_left` | 轮流模式：找到序号 / 还没找到的搜寻者数 |
| `#button_count` | 场上剩余按钮数 |
| `#round` | 当前轮次 |
| `#rounds` | 总轮数（配置，轮流模式下是周期数） |
| `#rounds_total` | 本局实际总轮数：经典模式 = `#rounds`，轮流模式 = `#rounds` × 参与人数 |
| `#player_count` | 当前参与人数 |
| `#need_tool` | 开局检查：集合点是否缺失 |
| `#cd` / `#cd_total` | Boss 栏：当前阶段的剩余秒数 / 总秒数 |
| `#cd_min` / `#cd_sec` / `#cd_s10` / `#cd_s1` | Boss 栏：剩余秒数拆成「分」「秒」「十位」「个位」，供标题拼 `m:ss` |
| `#pct` | Boss 栏：剩余百分比 0–100，喂给逐档分派 |
| `#c2` / `#c10` / `#c20` / `#c60` / `#c100` | 换算常量 |
| `#border_on` / `#border_r` | 活动边界：开关（0 关 / 1 开）与半径（0 表示跟随手动值；配置项，见第十一节） |
| `#bw_now` | 关闭边界时读回的实际直径，只用于聊天栏回显 |
| `#bx` `#bz` / `#cx` `#cz` | 贴边判定：按钮与集合点的坐标各 ×100（保留两位小数） |
| `#dx` `#dz` / `#lim` / `#neg` / `#out_border` | 贴边判定：两个方向的差值、限值 (半径−1)×100、取绝对值用的 −1、越界标记 |
| `#prep_time` `#hide_time` `#search_time` `#hint_period` `#protect_period` | 配置项 |

---

## 五、流程

### `ybih:load`

1. 建立全部记分板，侧边栏显示镜像榜 `ybih.board`。
2. **仅首次加载**执行 `config/apply` 写入默认配置；之后 reload 保留在书里改过的设置。
3. 执行 `config/defaults` 重置运行时状态，并**补写旧存档里没有的配置项**
   （`#mode`、`#confirm`、`#border_on`、`#border_r`）。
4. 执行 `game/reload_cleanup`：清除按钮方块与标记、清空玩家对局数据、还原游戏模式、
   **全员送回集合点**（排在拆等待室之前），
   若藏匿者正处在旁观模式则先送回集合点再切回冒险模式，**保留集合点与全部设置**。
5. 执行 `game/bar_init` 重建 Boss 栏——它随存档写进 `level.dat`，`/reload` 清不掉，所以先删后建。
6. 播报加载成功。

即 `/reload` 放弃当前对局，但设置与集合点保留。

### `ybih:tick`

1. 对局中每次自增 `#tick`（记首次发现时刻用）。
2. 侧边栏：每秒对一次在线名单（`game/board_sync`），每 tick 增量同步镜像榜。
3. 按 `#state` 分发到 `prep_tick` / `turn_tick` / `searching_tick` / `showcase_tick`。
4. `as @a run player/on_join` 幂等接管在线玩家；死亡玩家走 `player/on_death`。
5. 搜寻阶段才执行 `button/press_tick`。
6. `as @a[scores={ybih.trigger=1..}]` 分发聊天栏提交（确认 / 取消重放）。
7. `#protect_timer` 节流驱动 `button/protect_tick`。

### `ybih:start` → `game/start_check` → `game/start_begin`

1. `game/start_check` 检查开局条件：
   - 非旁观玩家只有 1 人时提示一句「搜寻阶段不会有人按按钮」，但**照常开局**；
   - 集合点缺失则由 `game/start_tools` 发放设置书并提示，**不开局**；
   - 人数与集合点都齐全才继续。
2. `start_begin`：清场，`#round = 1`，重置分数、发现次数、首次发现时刻、回合与玩家标签。
3. 所有非旁观玩家执行 `player/join_game`：分配 ID、记录原游戏模式、转冒险模式。
4. 未入队玩家的 `ybih.id` 清零。
5. 统计 `#player_count`，算出 `#rounds_total`：经典 = `#rounds`；轮流 = `#rounds` × 人数
   （轮流模式的这个值只用于显示，收官判据是 `ybih.turn`，见第九节；每轮开头会按当前参与者数重算）。
6. 全员传送到中心点。
7. `#state = 1`，载入准备倒计时，`game/bar_show` 把 Boss 栏交给参赛者并立刻刷一次，
   按当前模式显示副标题。

### 每秒逻辑（`game/second_tick`）

由 `#actionbar_timer` 每 20 tick 触发一次：推进对应阶段的秒数、给出操作提示、
在搜寻阶段递减提示计时，并判定各阶段是否到点。

- 准备到点 → `game/enter_turn`
- 藏匿到点 → `game/turn_timeout`
- 搜寻到点 → `game/end_round`

Boss 栏放在**全部阶段判定之后**刷新，这样切换阶段时标题立刻跟上、不会慢一拍。

### 倒计时显示（Boss 栏）

倒计时走屏幕顶部的 Boss 栏，不再占用物品栏上方。

| 函数 | 调用点 | 作用 |
|---|---|---|
| `game/bar_init` | `load` | 先 `remove` 再 `add`，重建 Boss 栏并配好颜色、样式与 `max 100` |
| `game/bar_show` | `start_begin` | 把可见玩家设为参赛者并立刻刷一次 |
| `game/bar_update` | `second_tick` 末尾，以及 `turn_next` / `enter_searching_run` / `next_round` 末尾 | 刷新可见玩家、进度条、标题与颜色 |
| `game/bar_hide` | `cleanup_end` / `reset` | 收起 Boss 栏并断开玩家关联（只隐藏，不删定义） |
| `game/bar_value` | 由 `bar_update` 调用 | 把剩余比例 0–100 逐档写进进度条（101 档，构建脚本生成） |

标题形如 `第 1 / 2 轮 · 搜寻中 · 8:30`，准备 / 藏匿 / 搜寻各一条。三条都**不指定
`color`**，颜色由 Boss 栏自身的 `color` 属性统管，于是整条标题跟着剩余时间走：
过半绿、两成以上黄、不足两成红。

三个关键约束：

1. **`value` / `max` 是 int32 整数**，不是浮点。命令参数从 1.13 加入起就没变过
   （1.20.4 的 BossBar 命令类字节码里只有 `IntegerArgumentType`，没有 `DoubleArgumentType`），
   所以进度条写 `max 100` + 整数档位。
2. **`value` 代入不了记分板**：参数是字面量，也没有 `execute store` 目标；宏要 1.20.2 才有，
   而包 1 得覆盖 1.16。因此每秒先算百分比 `#pct`，再逐档分派。
3. **标题里的分数不会自己刷新**：`name` 中的分数在「设置那一刻」求值，之后固定不变，
   所以标题必须每秒重设一次。

`m:ss` 由三个分数组件拼成（`#cd_min` + `#cd_s10` + `#cd_s1`）——分数组件按原值显示，
前导零补不了，只能把秒拆成十位与个位。

Boss 栏会随存档写进 `level.dat` 的 `CustomBossEvents`，`/reload` 不会清掉，所以由
`bar_init` 负责重建、`bar_hide` 负责收起。

阶段切换大多经过每秒循环，但「玩家确认换人」「最后一人确认进入搜寻」「全员找到直接结算」
这三条是玩家动作或按下检测触发的，不经过 `second_tick`；这三处末尾各补一次 `bar_update`，
否则进度条会停在上一个人的比例最多 1 秒。

物品栏上方（actionbar）只剩「需要玩家动手」的两类提示：放置确认（`game/action_hint`）
与冷热提示（`game/hint_one`）。

---

### 侧边栏（`game/board_sync`）

侧边栏挂的是**镜像榜** `ybih.board`，而不是真实成绩 `ybih.score`。

原版服务端对**离线玩家**的分数行是保留的（Wiki：*players are shown even if offline*），
玩家一退出并不会让那一行消失 —— 想让人走了就从榜上消失，只能靠镜像：

- `ybih:tick` 每 tick 做一次**增量同步**：谁的两榜不一致就写一次，分数改动立刻可见。
- `game/board_sync` 每秒跑一次，统计**在线人数**与**在场 `ybih.id` 之和**；
  两者任一变化即说明有人进出，于是 `scoreboard players reset * ybih.board` 把整榜清掉
  —— `*` 代表记分板上所有记过分的名字、**不受在线与否影响**，是 Java 版唯一能触到
  离线分数行的写法（`*` 只对 `reset` 生效，见 MC-136858）—— 紧接着同一 tick 的增量同步
  把在线的人重新写回去。
- 离线这件事拿不到可靠信号（`*` 只能用在 `reset` 上，没法逐个持有人查询），
  所以还有一道**每 10 秒无条件重建**的兜底：一进一出恰好落在两次采样之间、
  两个快照又没变时，靠它把遗留的行清掉。

真实分数始终留在 `ybih.score` 里，所以**退出只是从榜上消失，成绩不丢、重连回来照旧**。
开局、`/reload`、点重置会直接把整榜清空。

### 饥饿与免伤

**开始游戏**（`game/start_begin`）会给每位参与者两份保险，之后一直挂着，
直到下一次 `/reload` 或点重置才撤：

- **免伤**：`minecraft:resistance` 999999 秒、等级 V。按 `20% × 等级` 算正好 100%，
  摔落、岩浆、火焰、溺水、怪物伤害全部免掉。**饥饿伤害不在抗性减免范围内**，
  虚空伤害（`out_of_world`）与 `/kill` 同样免不掉。
- **不挨饿**：`minecraft:saturation` 999999 秒、等级 V。Java 版的饱和带时长时
  **每 tick 补 `1 × 等级` 饥饿点与 `2 × 等级` 饱和度**，所以饥饿条永远是满的 ——
  这一条不是锦上添花：抗性挡不住饥饿伤害，两者合起来才真正不掉血。
  代价是**饥饿值满时吃不下任何食物**，包括金苹果。

`player/apply_buff` 负责给，并打上 `ybih_buffed` 作为「该有」的标记。
**死亡会清空全部状态效果**（喝牛奶、被外部 `/effect clear` 也一样），所以效果不能只发一次：

- `player/buff_guard` 每秒对带标记的人重发一次，挂在 `ybih:tick` 上、**不受 `#state` 限制**；
- `player/on_death` 在死亡的当 tick 立刻补回来，正常路径下没有空窗；
- `player/rejoin` 给重连回局中的人补发。

撤销只走 `player/clear_buff`，入口只有 `game/reload_cleanup`（`/reload`）与 `reset/run`（点重置）。
对局结束、按中止、退出对局身份都**不再撤除** —— 效果按约定挂到 `/reload` 为止。

## 六、藏匿阶段

### 两种模式的轮次结构

| | 经典 | 轮流 |
|---|---|---|
| `ybih.turn` 的含义 | 本轮是否已藏 | 本周期是否已藏 |
| 每轮藏多久 | 所有人各藏一次 | 只有一人藏 |
| 归零时机 | 每轮 `turn/reset` 归零 | 全员都藏过（一个周期轮完）才归零 |

`game/enter_turn` 进入藏匿阶段时：先 `turn/reset`（清 `placed` 与 `found`，
经典模式另外清 `turn`），然后交给 `game/turn_next`。
轮流模式开新周期由 `game/cycle_next` 负责（见第九节）。

### `game/turn_next`

1. 清掉 `ybih_current` 标签。
2. 在 `ybih.turn = 0` 的参与者里用 `turn/pick_best` 找出 `ybih.id` 最小者。
3. `turn/mark_current` 给他打上 `ybih_current`。
4. 重置 `#hide_timer`，发放全套按钮，调用 `turn/gather`。

### `turn/gather`

- `ybih_current` 传送到中心点；
- 其余参与者送进集合点正上方的密闭等待室；
- 给藏匿者显示「轮到你了」，给其余人显示等待提示。

### 放置注册

`advancement ybih:button_placed`（`placed_block` 触发器，不写 `conditions`、不写 `display`）
奖励函数 `ybih:button/on_place`：

1. 仅在 `#state = 2` 且 `@s` 带 `ybih_current` 时继续。
2. 撤销该进度以便重复触发。
3. `button/try_register`：先退回并收回上一次放下但还没确认的按钮（等于换位置），
   记录玩家 ID，从眼位开始 `button/ray_loop` 射线。
4. `button/ray_loop` 每步前进 0.1 格、最多 40 步（4 格），每步对**当前格与上下前后左右 6 个邻格**
   依次执行 `button/probe_here`：当前位置是按钮方块且没有标记才算命中。
   按钮由原版放在被点方块的邻格里，半砖、楼梯这类非完整方块的命中点在方块内部，
   视线射线不会经过按钮所在的那一格，所以必须顺带探测邻格。
   射线**不做遮挡判定**：跨版本没有可靠的「视线可穿过」标签，硬判会让水里、洞穴里
   放下的按钮注册不到。控制误认靠的是 4 格的长度上限，以及下面第 5 步的材质校验。
5. `button/register_here` 在命中位置召唤标记实体、按材质与朝向打标签。
   若该位置的材质不在本包按钮清单内（标记会带上 `ybih_unknown`），说明命中的多半是
   地图自带的按钮，此时**只撤掉标记、不碰方块**，并让射线继续往里找，
   直到找到玩家真正放下的那一个。
6. 材质识别成功后交给 `button/register_ok`：用 `ybih.owner_id` 记分板记录物主、
   用 `ybih.era` 记录本局编号，并给标记打上 `ybih_pending`。
7. 收尾按 `#confirm` 分流：
   - `#confirm = 2`（关闭）：直接 `button/confirm_place`；
   - `#confirm = 1`（开启）：`button/offer_confirm` 在聊天栏给出【确认】与【取消重放】。
8. `button/confirm_place` 只把材质识别得出（带本包材质标签）的按钮计入 `#button_count`；
   识别不出的走 `button/reject_unknown`，提示换个位置并撤掉标记。
   这一步是必需的：若把认不出的按钮计入数量，它的 `powered` 永远不会被 `press_scan` 读到，
   本轮就会因为「还剩一个按钮」而跑满 `#search_time`。

### 聊天栏确认

`button/offer_confirm` 把 `ybih.trigger` 复位并 `scoreboard players enable`，
再播报两个可点条目。点击通过 `run_command` 执行 `/trigger ybih.trigger set 1|2`，
以点击者本人为执行者，因此**不需要 OP**。`ybih:tick` 用
`as @a[scores={ybih.trigger=1..}]` 分发到 `button/trigger_run`：

| 提交值 | 处理 |
|---|---|
| 1 | `button/confirm_do` → 校验存在待确认按钮且本人是当轮藏匿者 → `confirm_place` |
| 2 | `button/redo_do` → `refund_pending` 退回材质 → 播报 → `retract_pending` 收回按钮与标记 |

无论走哪条分支，`trigger_run` 结束前都会把 `ybih.trigger` 清零。
`retract_pending` 只在该位置仍是按钮时才 `setblock` 空气，避免误删地图方块。

### `button/confirm_place`

去掉待确认标记、`#button_count` 加一、置 `placed` 与 `turn`、
清空背包中其余按钮、播音效、播报「已藏好按钮」、推进回合。

### 回合推进

`game/turn_advance`：

- 经典模式：还有 `turn = 0` 的人就 `turn_next`，否则 `game/enter_searching`；
- 轮流模式：本轮唯一一次藏匿已结束，直接 `game/enter_searching`。

### 超时

`game/turn_timeout` 扣 1 分、收回待确认按钮、清空背包按钮。
经典模式走 `turn_advance` 换下一位；轮流模式走 `game/turn_timeout_mode2`：
把 `#seekers_left` 置 0（藏匿者不得分）后直接 `game/end_round_run`，跳过搜寻阶段。

---

## 七、搜寻与收集

### 进入搜寻阶段

`game/enter_searching_run` 统一设 `#state = 3`、装载搜寻与提示倒计时，再按模式分流：

| | 经典 `enter_searching_classic` | 轮流 `enter_searching_rotate` |
|---|---|---|
| `ybih_current` | 全部摘除 | 保留在藏匿者身上（轮末结算与身份恢复都要用） |
| 搜寻者 | 全员回集合点 | 非藏匿者回集合点 |
| 藏匿者 | —— | 从等待室送回集合点、转旁观模式、给夜视 |
| 计数 | 播报场上按钮总数 | `#seekers_left` = 非藏匿者人数，`#found_seq = 0` |

轮流模式下藏匿者转旁观是为了让他能看完整场搜寻，同时必须离开藏匿点，
否则旁观位置等于直接暴露答案。`player/active_state` 对带 `ybih_current` 的玩家
跳过「强制换回冒险模式」，否则每 tick 都会把观战的藏匿者拉回来。

### 结束条件

`game/searching_tick` 按模式判定：经典模式 `#button_count ≤ 0`，轮流模式 `#seekers_left ≤ 0`；
两者都由 `#timer` 兜底。

### 按下检测

`button/press_tick` 每 tick **只遍历一次**全场按钮（`@e[type=armor_stand,tag=ybih_button]`，
待确认的不参与），把每个按钮交给 `button/press_scan` 逐个判定。
`press_scan` 先按材质标签做廉价分派（`@s[tag=材质]` 命中才去读方块状态），
检查 `<材质>_button[powered=true]`：点亮则 `button/on_press`，
未点亮则交给 `button/release` 摘掉 `ybih_pressed` 与 `ybih_active`。

遍历只覆盖 `ybih.era` 等于当前局编号的标记。回合结束时若按钮所在区块没有玩家，
`@e` 选择器看不到那些标记，清理会落空；靠局号隔离，上一局遗留在未加载区块里的按钮
不会被当成本局按钮 —— 否则任何人按下它都会得分，而它的 `owner_id` 是上一局的编号，
还会把「你的按钮被找到了」通知给不相干的人。

这样每 tick 的全场实体遍历固定为 1 次，与按钮数量、材质数量都无关；
旧写法按材质分组各扫一遍（10–14 个材质就是 20–28 次遍历），在地图实体多时开销会线性放大。

`powered` 属性名在 1.16 – 26.2 一致。按钮不会被红石充能点亮（它只是信号输出源），
但**木质按钮能被射出的箭、投出的三叉戟和风弹点亮**，且箭插在按钮上期间会一直保持
`powered`（直到箭消失，约 1 分钟）—— 这正是下面那条「同一个 `powered` 窗口只判定一次」
闸门要挡的情况。

按下判定入口是 `button/on_press`。归属判定分两步：**进度锁定交互对象，编号比对锁定是哪一个按钮**。

**第一步 —— 进度条件锁定「对着按钮交互」**（`advancement ybih:button_used`）：

进度带 `location` 条件过滤，只有对着按钮方块的交互才会触发。
挖方块、开箱子、点门都不再产生事件，因此**旁边有人碰了别的方块不会污染判定**。

`location` 是**谓词数组**（loot condition 列表），谓词要用 `location_check` 包起来：

```json
"conditions": {
  "location": [
    { "condition": "minecraft:location_check",
      "predicate": { "block": { "tag": "minecraft:buttons" } } }
  ]
}
```

**写成裸对象 `"location": { "block": ... }` 时 JSON 合法、数据包照常加载、日志也没有任何报错，
但条件永远不匹配**，奖励函数从不执行，表现是「按下去毫无反应」。构建期对此有校验。

触发器按包不同：包 1 用 `item_used_on_block`（1.16 的 20w20a 加入），包 2、包 3 用 `any_block_use`
—— 因为 **1.20.5 起 `item_used_on_block` 不再对「不产生使用效果的方块交互」触发**
（Mojira MC-267456），而搜寻阶段玩家常常是空手按按钮，正属于这一类。
`any_block_use` 恰好也是 1.20.5 加入、覆盖所有方块交互，与包 2 的下界正好重合。
两者的 `location` 结构相同。

**第二步 —— 射线锁定是哪一个按钮**：

进度只说明「交互目标是按钮」，不给出实体，所以 `button/on_use` 还要从眼位做一次射线
（`button/use_ray`，40 步 / 4 格、每步探 6 邻格）找出他正对着的那个标记，
把它的 `ybih.bid` 抄进玩家的 `ybih.used_bid`。

这一步只在玩家真的点了按钮时跑一次，不再给附近的每个玩家都跑一遍。

判定时，`press_scan` 把被按下标记的 `ybih.bid` 取出来，与玩家的 `ybih.used_bid` 比对，
**两边的编号对得上才算数**。时间窗（`#use_min = #tick - 2`）仍然保留，但只用于挡掉陈旧值：
玩家很久以前点过这个按钮、这次按钮被箭打亮，不该把他算成按下者。

选出的人交给 `button/press_claim` 统一裁决：`ybih.id` 等于物主则 `own_press`（只提示），
否则 `collect` / `found_one` 计分。**物主同样参与候选**，所以自己按自己的按钮
不会再被算到旁边看客的头上。

按钮编号由 `#bid` 发号，写在标记的 `ybih.bid` 上。它与 `#era` 同待遇、**跨局不重置**——
重置会让往局残留的标记与本届新按钮撞号，按下判定就会认错按钮。

**经典模式** → `button/press_begin`：

1. 若标记已带 `ybih_pressed` 则整段跳过：**同一个 `powered` 窗口只判定一次**。
2. 把本次按下的标记挂上 `ybih_active`，供 `button/consume` 定位要清掉的那一格。
3. 记录 `#press_owner` 与 `#press_bid`，按上面的编号比对选出按下者并 `press_claim`。
4. 一个人都没认领（例如按钮被箭打亮、而附近没有人）则不作数，
   等按钮弹起由 `button/release` 摘掉标记。

**轮流模式** → `button/press_mode2`：按钮不消失，判定方式与经典模式一致，
只是候选集额外要求 `ybih.found = 0`（本回合还没找到过），结算走 `button/found_one`。

### 结算

**经典 `button/collect`**：先把 `#button_count` 存进 `#gained` 并加到分数上
（`#button_count` 此刻含刚按下的这个，所以第 k 个被发现的按钮价值 `剩余数`），
记一次 `ybih.finds`、首次发现时记 `ybih.t_first`，播音效、通知物主，再 `consume`，
剩余计数归零则立即 `end_round`。

**轮流 `button/found_one`**：把 `#seekers_left` 存进 `#gained` 并加到分数上，
记 `ybih.finds` 与 `ybih.t_first`，置 `ybih.found = 1`，`#found_seq` 加一、
`#seekers_left` 减一，全服播报「第 N 个找到，+K 分」；`#seekers_left` 归零则立即 `end_round`。

- `button/own_press`（按的是自己的）：只提示一句，不得分，**按钮保留**（不执行 `consume`）。
- `button/consume`：`#button_count` 减一（只减到 0 为止）、把按钮方块设为空气，
  再把标记从 `ybih_button` 换成 `ybih_ghost` —— **不 kill**，理由见围观一节。

### 冷热提示

`game/hint_all` 每 `#hint_period` 秒对每个**非当前藏匿者**的参与者执行 `game/hint_one`：
`game/hint_scan` 在 `#hint_range` 格内遍历标记，只要存在一个 `ybih.owner_id` 不等于自己的
就提示「有」，否则提示「没有」。

**半径是逐档分派的**：`distance=..N` 是选择器参数、只收字面量、代入不了记分板，
所以构建脚本按 `HINT_RADII`（5 / 10 / 15 / 20 / 30 / 50）生成六条扫描命令，
只有命中的那一条会真的去遍历实体。物品栏上方的文案用 `score` 组件直接读 `#hint_range`，
改完设置数字自动跟着变，不用改文案。

---

## 八、按钮保护

`button/protect_check` 每 `#protect_period`（默认 5）tick 执行一次，同样**只遍历一次**全场按钮，
对每个标记只做一次 `unless block ~ ~ ~ #minecraft:buttons` 判定：位置还有按钮就跳过，
没有才记账并分派：

- `ybih.fixed ≤ 3` → `button/protect_restore` 按材质与朝向把按钮放回去。
- `ybih.fixed ≥ 4` → `button/give_up` 收回按钮：`#button_count` 减一（同样只减到 0 为止）、
  给物主一句提示、杀掉标记。

**两处减法都带 0 下界**：`ybih_button` 里除了玩家藏好的按钮，还有还没确认的、以及地图自带材质的标记，
它们从没被 `#button_count` 加过；照着减会把数字带成负数，而 `searching_tick` 用
`#button_count ≤ 0` 判定本轮是否按完 —— 一旦为负，搜寻阶段开局即结束。

**这道上限是必须的**：水会一次次把按钮冲掉，而按钮**被破坏时会掉落一个物品**、
`setblock` 放回去则不会 —— 两者一循环就成了刷物品机器，每 5 tick 复制一个按钮。
数到 4 次（约 1 秒）就止损，不再陪它无限循环。

**放置时先拦一道**：`button/fluid_check` 在 `register_ok` 里检查按钮的**四个水平邻格与正上方**，
**只要那些方向是水（不分水源与流水）或岩浆就直接作废**，由 `button/fluid_reject` 退回材质、
清掉方块与标记并提示 —— 和贴边界的处理完全同构，玩家不会白藏一次。

判据不再区分水源与流水，是因为 Java 版里按钮**本来就存不住水**：Wiki 把按钮归在
「不能泡在水里」那一档（`Pops off` —— 尝试放置会被水替换、方块破坏掉落），备注又写明
会被流水破坏。只拦流水挡不住真正会出事的位置：水下、池底、水下建筑的墙上，
水迟早漫进按钮格。

**只看水能来的方向**：水不会向上流，所以**正下方是水不算**，桥面、水下天花板那类位置照常能藏。
含水的方块（含水楼梯、含水栅栏那类）不算 —— 里面的水是困住的，不会流出来，
紧挨着它放按钮是安全的。

**两道校验互斥，水优先**：水那道退回时会连标记一起删掉，边界检查再拿清零后的坐标去算，
会得到一个巨大的差值而误判成越界，结果是两条提示一起弹、材质也被退两遍。
所以边界检查整段挂在 `#wet matches 0` 上。

水若是在放下**之后**才流过来，放置检测拦不住，这种情况由上面的 `give_up` 兜底。

`protect_restore` 按注册阶段 `button/tag_material` 与 `button/tag_face` 记下的材质与朝向逐组合还原，
因为只在按钮真的丢失时才执行，平时不产生任何开销；旧写法把「材质 × 朝向」的 120–168 条判定
全部放在每 5 tick 的主路径上，每次都要做 120–168 次全场遍历。

位置被换成**另一种按钮**的情况不再纠正（位置已被占用，正常玩法下不会发生）。

---

## 九、轮次、结算与清理

### `game/end_round`

仅在 `#state = 3` 时执行 `game/end_round_run`，避免重复触发。

### `game/end_round_run` → `game/showcase_begin` → `game/end_round_finish`

本轮收尾被拆成两段：**围观是异步的**（每个按钮停 10 秒），挤不进一次调用里跑完。

1. `end_round_run`：按模式结算（经典跑 `game/award_survive_all`，轮流跑 `game/award_hider`），
   `game/ranking` 播报本轮结束与完整名次，然后把收尾交给 `game/showcase_begin`。
2. `showcase_begin` 数一下场上还剩几个本局按钮：一个不剩就直接调 `end_round_finish`，
   还有就进围观阶段。
3. `end_round_finish`：`game/cleanup_buttons` 清除本轮按钮与按下标记、把观战中的藏匿者
   恢复成冒险模式，再交给 `game/classic_next`（经典）或 `game/rotate_next`（轮流）决定续轮或收官。

### 轮末围观（`game/showcase_*`）

**展示对象是本局每一个藏过按钮的人**，不再限于「没被找到的」。判据是两类标记：

| 标记 | 含义 | 围观时的处理 |
|---|---|---|
| `ybih_button` | 还插在场上、没被按到 | 方块留在原地 |
| `ybih_ghost` | 已经被按掉 | 方块早被 `consume` 设成空气，按记录临时摆回去 |

因此 `button/consume` 不再 `kill` 掉按下的标记。**非玩家实体一旦死亡，它名下的分数会被一并
清空**，而位置、材质标签、朝向标签、`ybih.owner_id` 全记在标记身上 —— 杀掉就等于把这条记录
抹掉。改成只把它从 `ybih_button` 摘出来换成 `ybih_ghost`：标记原地留着，而清场、保护、
按下检测、冷热提示都只认 `ybih_button`，它自动退出这四个系统。
`ybih_pressed` 要顺手摘掉 —— 它是「同一个 powered 窗口只判定一次」的闸门，本来由弹起时的
`release` 负责摘，而这个标记已经不会再被 `press_scan` 遍历到，留着就是永久残留。

- `showcase_begin`：分别数两类标记里 `ybih.era = #era` 的，加起来写进 `#show_total`。
  **围观开关（`#showcase_on`）关掉时两次数数都跳过**，`#show_total` 保持 0，
  于是直接走 `end_round_finish`，不做任何传送。
- `showcase_start`：把两类标记都挂上 `ybih_showcase`（**先挂展示标签再摘 `ybih_button`**，
  顺序反过来第二轮就选不中它们了）。`ybih_ghost` **保留不摘** —— 它是
  「这个按钮当时被找到了」的判据，`showcase_bar` 要靠它换文案。
  随后按记录的材质与朝向把被按掉的按钮摆回去（走 `game/showcase_restore`），
  条件有两条：**那一格必须是空气** —— 万一玩家后来在旧位置放了别的方块，覆盖上去、
  围观结束再清成空气，就等于平白删了他一个方块；**而且按钮不能泡在水里** ——
  Java 版按钮存不住水，摆回去当场会被流水冲掉并掉落一个按钮物品，这里先跑一次
  `button/fluid_check`，`#wet` 被置 1 就跳过。最后 `#state = 4`、全员转旁观并发夜视。
- **区块强制加载统一走 `ybih_pinned` 凭据**：围观是隔着上百格依次传送的，
  玩家被带到第一个按钮之后，其余按钮的区块超出模拟距离就会卸载，标记随即从 `@e` 的视野里
  消失，队列会当场断掉，所以待展示按钮的区块必须提前钉住。
  钉的时机有两处，都取「区块必然加载」的那一刻：
  `button/confirm_place_ok`（确认藏匿时，人还站在按钮旁）与
  `button/consume`（按钮被按下时，人就站在旁边）。
  `showcase_start` 只做兜底，给还没打过标签的补一次钉。
  两处 `add` 之后都给标记打上 `ybih_pinned`，表示「这个标记申请过强制加载」。
  释放统一由 `game/showcase_end` 与 `util/cleanup_all` 按这个标签执行，
  **且都排在 kill 标记之前** —— 标记一没，后面的 `forceload remove` 就再也选不中它，
  区块会被永久留在 `chunks.dat` 里。因为 `/reload`、重置、整局结束三条路径都经过
  `cleanup_all`，任一时刻打断都不会漏放。
  只在 `showcase_start` 钉的话，**从头到尾没被按到的远处按钮会整只漏展示**：
  它不经过 `consume`，到轮末藏匿者早被传回集合点、区块已卸载，
  `showcase_begin` 的 `@e` 数不到它，`#show_total` 少数，它就永远不会被展示。
- `showcase_tick` 由 `ybih:tick` 在 `#state = 4` 时驱动，每 tick 扣 `#show_timer`；
  归零就 `showcase_step` 挑下一个。每个按钮**停 200 tick（10 秒）**，`showcase_end` 统一放开
  这些区块的强制加载。
- **收尾判断必须和展示互斥，而且排在它前面**：`showcase_step` 先把 `#show_idx` 加一，
  超过 `#show_total` 才收尾，否则重置停留计时并挑下一个。写成「先展示、紧接着
  `unless entity @e[…]` 收尾」的话，最后那个按钮刚被打上 `ybih_shown`，`unless` 立刻成立，
  `showcase_end` 会当场把它清掉 —— 只留两个按钮时，看到的就是「第一个停满 10 秒、
  第二个一闪而过」。
- **「是否看完」比编号，不数 `@e`**：队列万一因为区块没跟上而少选出一个，
  数实体的写法会把「还有没展示的」误判成「全看完了」；比编号最多空等一轮就自然收尾。
- **出场顺序按藏匿先后，不用 `sort=nearest`**：`showcase_pick` 的调用链
  `ybih:tick` → `showcase_tick` → `showcase_step` → `showcase_pick` **全程没有执行实体**，
  所以 `sort=nearest` 的参考点会退化成命令原点（世界原点），顺序成了「离原点由近到远」，
  隔着几百格来回绕。改用注册时记下的编号 `ybih.seq`：
  `button/register_ok` 每登记成功一个就 `add #seq 1` 再写进标记，
  `showcase_pick` **两趟**求最小值（第一趟把每个候选的编号折进 `#show_best` 取小，
  第二趟谁等于它谁上场）。`if score` 的右侧不能是字面量整数，所以哨兵用一个
  持有者 `#c_max`，比较方向也写成「候选 < 当前最优」（左边必须是持有者）。
  拿不到编号（`seq` 为 0）的标记会排在最前被优先选中 —— 这类标记要么是旧局残留，
  要么朝向标签也丢了，本来就选不出站位。
- **「先 operation 再 add 递增」那条老坑不再适用**：它说的是「想让每个实体拿到不同的号」时
  不能在 `as @e` 里当场发号（`as @e` 是「对每个实体执行同一段命令」，给不出各不相同的值）。
  现在的编号是在 `register_ok` 里**一个标记一次调用**发的，不存在这个问题。
- **去重用两个标签分工，不能合并**：`ybih_shown` 标记「已经展示过」，挑选时排除它；
  `ybih_showing` 单独标记**当前正在展示的那一个**。两者不能合并成一个 ——
  `ybih_shown` 是累积的（展示过的都带着，直到下一轮才清），
  定格期间拿它 `limit=1` 取到的是**最早**展示过的那一个，
  `showcase_pin` 会把人一路按回第一个按钮的位置，
  表现就是「每次都被传送回上一个按钮」。`ybih_showing` 在 `showcase_show` 里
  先整批摘掉再给当前这个挂上，任何时刻只有一个。
- `showcase_show` 负责这一帧的展示：打上 `ybih_shown`、把 `ybih_showing` 挪到当前这个，
  **按标记上有没有 `ybih_ghost` 把 `#show_found` 置 0 或 1**，再依次调 `showcase_glow`、
  `showcase_bar`、`showcase_view`，最后把 `#freeze` 置为 20（见下）。
  **顺序不能变**：高亮的配色与 Boss 栏的文案都照 `#show_found` 分派，得先把它定下来。
- **站位由构建脚本生成的 `game/showcase_view` 分派**，但它只负责「传送 + 转向」这一帧，
  钉位期间每 tick 用的是同样生成的 `game/showcase_pin`。两者都由标记的**朝向标签**
  进行十二路分派，末尾各有一条「十二条朝向全不中」的兜底（`unless entity @s[tag=...]` 全挂上）：
  朝向标签被外部命令破坏时至少不会干站着看上一个位置。
  这里选兜底而不是「在 `showcase_pick` 里排除没有朝向的标记」，是因为排除会让那个按钮
  永远不被展示，与「每个藏过的人都展示」冲突。
- **传送后要定格一秒**（`#freeze = 20`）：玩家可能还按着方向键，客户端又已经按旧速度预测了位移，
  刚被 `tp` 到新位置就会顺着原方向飞出去。
  `showcase_tick` 每 tick 递减 `#freeze`，在它到 0 之前调 `showcase_pin` 把所有人按回站位。
  **`showcase_pin` 只能给位置、不能带角度** —— 带上角度会连玩家的视角一起锁死，转不了头看周围。
  `showcase_end` 要把 `#freeze` 归零，免得多余的值漏到下一个阶段。
- `showcase_bar` 由 `showcase_show` 和 `showcase_tick` 共同调用：按 `#show_found` 分派两套
  文案（「没被找到的按钮」/「已被找到的按钮」），写入「第几个 / 共几个 · 还剩几秒」，
  并让 `#show_refresh` 归零以重新计时。`showcase_tick` 每 tick 按剩余停留时间
  推一次进度条（复用 `bar_value`）、每秒重写一次标题 —— **`#state = 4` 期间 `second_tick`
  不跑，围观的 Boss 栏只能由这里自己维护**。
- **围观高亮：只亮当前这一个按钮，以及它的物主，红=已被找到、绿=没被找到**。
  发光轮廓的颜色由实体所属**队伍**的 `color` 决定，所以建两个队（`ybih_found` 红、
  `ybih_notfound` 绿），在 `load` 里建一次。队伍只装展示标记与当前那个按钮的物主，
  其余玩家一律不进队。
  **「只亮当前」不靠记「上一个是谁」**：每次切换先用 `effect clear` 把全部展示标记
  与参与者的发光一次清光，再给当前这个挂队上色 —— 清光这一步本身就带走了上一个。
  物主本人也进同一个队、同色发光，他的名字还会写进 Boss 栏标题。
  名字只能靠 `{"selector":"@s"}` 渲染，而 `@s` 只有在以物主为执行者时才指向他，
  所以给物主挂一个 `ybih_show_owner` 标签把他钉住，之后每秒的 `showcase_bar`
  都借这个标签以他的身份重发一次标题；物主掉线时退回不带名字的版本，秒数照常走。
- `showcase_end`：放开钉住的区块、把展示位置**仍然是按钮**的方块清成空气、清掉全部展示标记、
  把 `#freeze` 归零、撤掉**参与者**的夜视（`@a[tag=ybih_player]`，别误清没参与这局的旁观者的长期夜视）、
  撤销参与者身上的发光与队伍身份、撤掉物主标签，
  再把参与者恢复成**入队时记下的原模式**（只处理当前是旁观的人 —— 无脑按标签恢复会把
  「入队时是创造、局中自己切回冒险」的人拽回创造），然后接 `game/end_round_finish`。
  「仍然是按钮」这一个条件同时管住三类位置：场上没被找到的、围观期间摆回去的，
  以及**摆回时那一格不是空气因而没有摆的**（第三种不能被误清）。
  标记是被 `kill` 掉的，它们身上的发光随实体一起消失，玩家身上的才要手动清。

`ybih_ghost` 有两条清理出口：`showcase_end` 里的 `kill @e[tag=ybih_showcase]`，
以及 `util/cleanup_all` 里的 `kill @e[tag=ybih_ghost]`（换轮、重置、重载都会经过它）。
两条都不必再区分「是不是正在围观的那个」：区块强制加载已经在 `cleanup_all` 开头
按 `ybih_pinned` 释放过了，标签也随之摘掉，所以这里可以放心全杀，
不会留下没人释放的强制加载。
另外 `button/register_ok` 在登记新按钮时会顺手杀掉**同格**的旧记录 ——
否则玩家在旧位置重新藏一个，围观时那一格会被展示两次。

**被保护机制收回的按钮不在此列**：`button/give_up` 走的是 `kill`。那条位置反复被水或爆炸
冲毁、方块早已保不住，物主当时也已经收到收回提示，再展示一次只能看到一片水或坑。

### `game/classic_next` / `game/rotate_next`（续轮判定）

**判定与执行必须分开**：`next_round` 会把 `#round` 加一，如果在同一个函数里先执行
续轮、再用 `unless #round < #rounds_total` 判收官，第二个条件会被第一个执行改掉，
结果「下一轮刚开就被立刻结算」。因此续轮判定一律先把结果写进 `#more` 标记，再按标记分派：

- 经典（`classic_next`）：`#round < #rounds_total` → `#more = 1`，续轮；否则收官。
- 轮流（`rotate_next`）：
  1. 场上没有参与者 → `#more = -1`；
  2. 存在 `ybih.turn = 0` 的参与者（本周期还没藏过）→ `#more = 1`，进下一轮；
  3. 本周期人人藏过、且 `#cycle < #rounds` → `#more = 2`，由 `cycle_next` 开新周期；
  4. 其余（人人藏过且周期用完）→ `#more = 0`，收官。

`ybih.turn` 在轮流模式下表示「本周期是否已藏」：确认藏匿（`button/confirm_place`）
或藏匿超时（`game/turn_timeout`）都会置 1，只在开新周期时归零。
`cycle_next` 把 `#cycle` 加一、全员 `ybih.turn` 归零、播报新周期开始后进下一轮。

### `game/award_survive_all` / `award_survive` / `award_survive_probe`（经典）

对每个已确认藏匿的参与者，遍历全场按钮标记；若存在 `ybih.owner_id` 等于自己的标记，
说明按钮还没被找到，加 1 分并提示。按钮的价值序列正好接在余量分的末尾，
所以不会和「最后一个被找到的人」并列。未确认（超时）的人被 `ybih.placed = 1` 条件排除在外。

### `game/award_hider`（轮流）

藏匿者按轮末剩余的 `#seekers_left` 加分，也就是**拿走剩余搜寻者对应的那一份**：
3 个搜寻者全找到 → 0 分，找到 2 个 → +1 分，一个都没找到 → +3 分。
每轮的总分固定为 `S(S+1)/2`，要么被搜寻者按找到顺序拿走，要么留给藏匿者。
（`#seekers_left` 的初值是搜寻者人数，每有一人找到才减一，所以「一个都没找到」时它是 `S`。）

### `game/ranking` / `game/ranking_final`

播报本轮结束标题后调用 `game/rank_broadcast`；最终排名播报总轮数标题后再调用同一函数。

`rank_broadcast` → `game/rank_step` 循环，直到所有参与者都有名次：

1. 复位 `#best_score` / `#best_finds` / `#best_tfirst` / `#best_id`；
2. 对每个还没排名的参与者跑 `game/rank_scan`，四级比较：
   分数高 → 发现次数多 → 首次发现时刻早 → `ybih.id` 小；
3. 胜出者由 `rank_take` 把四项值抄进 `#best_*`，`rank_mark` 按 `#best_id` 回标 `ybih_top`；
4. `#ranked` 加一后播报「第 N 名：玩家 — S 分 · 发现 F 次」，给该玩家打 `ybih_ranked`，递归下一名。

因为最后一级是唯一的 `ybih.id`，名次是严格全序、不会并列。
**注意区分「名次并列」与「分数并列」**：经典模式 4 人局里有 2 人存活时两人都是 1 分，
轮流模式同理。名次靠后三级比较分出来，分数本身是可以相同的。

### `game/next_round`

`#round` 加一，把新加入的非旁观玩家并入本局，重置所有人的藏匿与找到状态
（`ybih.turn` 只在经典模式重置，轮流模式要保留周期进度），
**轮流模式按当前参与者数重算 `#rounds_total`（只用于显示）**，
传送到中心点，`#state` 回到准备阶段。**分数保留。**

### `game/final_summary`

播报最终排名后执行 `game/cleanup_end`，整局结束。

### `game/cleanup_buttons`

先把观战中的藏匿者传送回集合点再切回冒险模式（旁观可以飞进方块内部，
原地切回会窒息），清掉夜视；然后用 `util/clear_placed_blocks` 把每个注册过的按钮方块
还原成空气（执行前确认该位置仍是按钮，避免误删地图方块），
再清除全部标记、背包中按钮与 `ybih_current`。轮间使用，不动玩家身份。

### `game/cleanup_end`

在 `cleanup_buttons` 基础上，按 `ybih_gm_*` 标签还原玩家游戏模式、清除全部对局标签、
`#state`、`#timer`、`#round` 归零。整局结束或中止时使用；`/reload` 走的是 `game/reload_cleanup`。

**全员回集合点这一步排在 `util/remove_wait_room` 之前**：按中止时可能还有人被关在等待室里，
先抽掉地板再传送，人就成了自由落体（抗性提升此时也已经撤掉）。同一段里兜底收掉
围观可能留在世界里的按钮。

### `ybih:stop` / `ybih:reset`

- `stop`：直接执行 `cleanup_end`，不发奖励、不播报排名。
- `reset`：仅空闲状态可用，额外清空所有玩家的对局分数与 ID。

---

## 十、观战与重连

- 对局中进入的玩家若没有 ID，执行 `player/spectate`：转旁观、给夜视、传送到中心点。
- 重连玩家（ID 仍存在）执行 `player/rejoin`：恢复参与者身份与冒险模式；
  若在轮流模式的搜寻阶段回来，直接置 `ybih.found = 1`，本轮不参与抢分，避免打乱找到顺序。
- 死亡不淘汰：`player/on_death` 清掉死亡计数，对局中补回冒险模式。
- 空闲状态下的玩家若残留 `ybih_player` 标签，由 `player/leave_game` 摘除。
- 轮流模式下藏匿者在搜寻阶段是旁观：`player/active_state` 对被标为 `ybih_current` 的玩家
  跳过「强制换回冒险模式」，轮末由 `cleanup_buttons` 统一恢复。

---

## 十一、配置、集合点与活动边界

### 配置

`config/apply` 写字面量默认配置，**仅首次加载时执行**；之后 reload 保留在书里改过的值。
想恢复默认就删掉 `ybih.config` 目标或手动执行 `/function ybih:config/apply`
（注意边界两项不在 apply 里，得手动 `scoreboard players set`）。
`config/defaults` 写运行时初始状态，每次 reload 都把运行时值重置；配置项只**补缺失的**，
不覆盖已设过的。

| 配置项 | 默认值 | 含义 |
|---|---|---|
| `#mode` | 1 | 游戏模式：1 经典 / 2 轮流 |
| `#confirm` | 1 | 放错确认：1 开启 / 2 关闭 |
| `#prep_time` | 10 | 准备阶段秒数 |
| `#hide_time` | 60 | 每人藏匿回合秒数 |
| `#search_time` | 600 | 搜寻期秒数（兜底） |
| `#hint_period` | 60 | 冷热提示间隔秒数 |
| `#hint_range` | 10 | 冷热提示的探测半径（格），六档 5 / 10 / 15 / 20 / 30 / 50（档位表见 `HINT_RADII`） |
| `#protect_period` | 5 | 按钮保护检测间隔 tick |
| `#rounds` | 1 | 总轮数；轮流模式下是**周期数** |
| `#border_on` | 0 | 活动边界：**0 关闭 / 1 开启**（由 `config/defaults` 补写，不在 `config/apply` 里） |
| `#border_r` | 100 | 活动边界半径（格），书里九档 20 / 30 / 40 / 50 / 60 / 70 / 80 / 90 / 100（同上）；旧存档遗留的 150 / 200 由 `config/defaults` 归并到 100 |

新加的配置项在旧存档里没有值，因此 `config/defaults` 会用
`execute unless score #mode ybih.config matches 1..` 这类判断补一份默认值。
`#mode` 与 `#confirm` 的取值是 1 / 2 而不是 0 / 1，就是为了让「未设置」和
「设为关闭」能被区分开，否则每次 reload 都会把关闭态重置回开启。

### 管理员设置书

`admin/book` 发放一本 `written_book`，游戏内所有可调项都做成书页里的可点击条目，
点击通过 `run_command` 执行，命令以玩家为执行者。共 12 页：

| 页 | 内容 |
|---|---|
| 1 | 【目录】每行「几页　这页讲什么」，点条目直接跳到对应页 |
| 2 | 【开局操作】查看当前设置 / 开始游戏 / 中止当前对局 / 重置全部数据 |
| 3 | 【游戏模式】切到经典模式 / 切到轮流模式 |
| 4 | 【放错确认】开启确认 / 关闭确认 |
| 5 | 【点位与边界】集合点 / 边界开关与半径 |
| 6 | 【准备阶段时长】5 / 10 / 20 / 30 秒 |
| 7 | 【一个人能藏多久】20 / 30 / 45 / 60 / 90 / 120 秒 |
| 8 | 【搜寻阶段时长】180 / 300 / 450 / 600 / 900 秒 |
| 9 | 【冷热提示】间隔 15 / 30 / 60 / 120 秒；探测半径 5 / 10 / 15 / 20 / 30 / 50 格；关闭提示 |
| 10 | 【轮末围观】围观开 / 围观关 |
| 11 | 【总轮数 / 周期】1 / 2 / 3 / 5 / 8 |
| 12 | 【规则与计分】规则说明 |

#### 排版常量

书页文字区是固定尺寸，排版按这些常量算（在 1.20.4 / 1.21.5 / 1.21.10 / 1.21.11 上一致）：

| 常量 | 值 |
|---|---|
| 文字区宽 | 114 像素（`font.split(component, 114)`） |
| 行距 / 首行 y | 9 像素 / y = 32 |
| 一页可见行数 | **14 行**（`128 / 9` 整除） |

一页固定排 14 行：内容不足时在内容与页脚之间补空行，**页脚固定落在第 14 行**，
也就是页面最下方。内容区上限 12 行（留一空行再放页脚）。

单行宽度按「半角 6 像素、全角 9 像素、空格 4 像素」估算，超过 100 像素即视为会折行；
折行会把页脚往下顶，所以构建期直接报错拦下。构建期同时校验：跳页链接落在有效页范围内、
每页内容不超过 12 行、单页字符数不超过 250、整页排出来不超过 14 行。

#### 页面结构

| 组成 | 样式 | 来源字段 |
|---|---|---|
| 标题 `【X】` | 深红 | `title` |
| 备注 | 深灰 + 斜体 | `note` |
| 分隔线 `——————————` | 深灰 | 固定常量 |
| 说明行 | 深灰 | `lines` |
| 条目 `· X` | 墨黑 + 下划线（可点） | `items`，`color` / `bold` 可覆盖 |
| 目录行首 `N页　` | 深灰，不可点 | `items[].prefix` |
| 悬停提示 | 原生 tooltip | `items[].tip` |
| 页脚 `第 N / 12 页　目录` | 深灰 + 斜体；`目录` 深紫带下划线，可点回第 1 页 | 自动生成 |

条目字段：`cmd` 点击执行命令、`page` 点击跳页、`tip` 悬停提示、`sameRow` 与下一条排同一行（两列）、
`prefix` 行首文字、`color` 覆盖颜色、`bold` 加粗。说明行一律写短句，更长的解释放悬停提示里由 tooltip 折行。

**可点项一律带下划线**：书页上没有按钮外观，下划线是「这一行能点」最直接的信号 ——
一度试过去掉下划线、只靠颜色区分条目与说明，实际辨认起来太费劲，所以又加了回来。
加粗只留给开局、中止、重置三个关键动作。

文案、排版与三个包的渲染都在 `src/book.mjs`，`src/manifest.mjs` 只做转出。

#### 点击与悬停的字段

| | 包 1/2（1.16–1.21.4，JSON） | 包 3（1.21.5+，SNBT） |
|---|---|---|
| 执行命令 | `clickEvent{action:"run_command",value:"/…"}` | `click_event:{action:'run_command',command:'/…'}` |
| 跳页 | `clickEvent{action:"change_page",value:"3"}`（页号是**字符串**） | `click_event:{action:'change_page',page:3}`（页号是**整数**） |
| 悬停 | `hoverEvent{action:"show_text",contents:"…"}` | `hover_event:{action:'show_text',value:'…'}` |

**命令必须带 `/` 前缀**，否则客户端拒绝执行。

#### 书的 NBT 写法

| 包 | pages 里放什么 |
|---|---|
| 1 | `written_book{pages:['<JSON 数组>',...],title:"...",author:"..."}` |
| 2 | `written_book[minecraft:written_book_content={pages:['<JSON 数组>',...],title:"...",author:"..."}]` |
| 3 | `written_book[minecraft:written_book_content={pages:[[<组件>,...],...],title:"...",author:"..."}]` |

1.20.5–1.21.4 的书页是「装着 JSON 的字符串」；**1.21.5 起书页本身就是文本组件**，
一页可以是一个组件列表，不再套字符串。换行的层级也随之不同：

| 包 | 文件里写 | 解析层数 |
|---|---|---|
| 1/2 | `\\n`（两个反斜杠） | 命令串一层 → JSON 一层 → 真换行 |
| 3 | `\n`（一个反斜杠） | SNBT 一层 → 真换行 |

配色：书页底色是米黄，十六色里只有深色系读得清、亮色一律发虚，所以只用五个 ——
深红（页标题、关闭与危险操作）、墨黑（正文与普通设置项）、深绿（开启）、
深紫（查看与切换、目录链接）、深灰（副标题、说明、页脚）。

模式、放错确认与边界开关是**手写函数**（`config/mode_1`、`config/mode_2`、`config/confirm_on`、
`config/confirm_off`、`config/border_on`、`config/border_off`、`config/border_help`）—— 前三者对局
进行中禁止切换；边界那三个里只有 `border_off` 带额外动作（立刻撤销世界边界），
开关与半径都只记设置，因为边界要等开局才出现。
其余数值选项由一个生成函数承担（如 `config/hide_60`、`config/border_r100`、`config/border_manual`），
函数内改值后统一调用 `config/notify`，保证有点击音效与「当前设置」回执。
若直接在书里写 `scoreboard players set`，执行后不会有任何可见反馈。

### 集合点与活动边界

`game/start_check` 在开局时检查集合点；缺失则由 `game/start_tools` 发放设置书并提示，
**不开局**。管理员站到目标位置、点书里对应条目即可：

- `config/set_center_here` 设集合点

它在**执行者站立的位置**召唤带标签的标记实体，并 `forceload` 该区块。
（不对齐到方块中心，否则玩家被传送回来会卡在方块里。）

集合点同时决定两件事：

**高空等待室。** 开局时由 `util/build_wait_room` 在集合点正上方砌一间石英房子
（它开头会先调 `util/remove_wait_room` 把上一间拆掉，所以集合点挪位后天上不会留孤儿房子）
（总高 5 格：地板 1 + 内空 3 + 顶 1，内空 9×9，天花板嵌 2×2 海晶灯），`turn/gather`
把没轮到的人关进去；不透明所以看不到外面。

**基准高度按包注入**，因为世界可放置范围分两档：1.16–1.17 是 `0~255`，1.18 起是
`-64~319`（本机 1.20.4 与 1.21.11 的 `dimension_type/overworld.json` 都是
`min_y:-64, height:384`）。而**自然地形最高能到 256**，所以 1.18+ 必须抬到它上面才躲得开山体：

| 包 | 基准高度 | 原因 |
|---|---|---|
| 包 1（1.16.2–1.20.4） | **y=245** | 跨了这条分界，只能用 ≤255 才兼容 1.16.2–1.17 |
| 包 2（1.20.5–1.21.4） | **y=300** | 全落在 1.18+，抬到地形之上 |
| 包 3（1.21.5–26.2） | **y=300** | 同上 |

结构内部一律以标记为基准取相对坐标（`~`、`~1` … `~4`），换包时只改一个数字，
由 `tools/build.mjs` 把 `WAIT_ROOM_Y` 注入源码。

整局结束与 `/reload` 由 `util/remove_wait_room` 拆掉，拆之前先把里面的人送回集合点；
集合点不在就整体不拆，免得把人从高空摔下来。拆除范围铺到 `~8`，把老存档里建偏了的
那间也一并清掉。`turn/gather` 送人前还会确认地板
确实是石英，防止 fill 万一没建成而把人放下去。

**活动边界。** 以集合点为中心的世界边界，书里给开关、九档半径（20 到 100、每 10 一格），
再加一档「跟随手动」。

**设置与生效是分开的**：书里那些条目**只写记分板、不动世界**；边界真正出现是在**开局那一刻** ——
`game/start_begin` 在 `#border_on` 为 1 时调 `util/border_apply`（对中 + 按半径设尺寸）。
`#border_r` 为 0 表示「跟随手动」，这时 `border_apply` 的九个档位都不命中、尺寸保持不动，
手动 `/worldborder set` 改的值就能被开局沿用。

**撤销只有一个入口**：`util/border_reset`（直径放回 59999968、中心回 0 0，并读回实际直径）。
它被四处调用 —— `config/border_off`（点关闭时立刻撤销）、`game/reload_cleanup`、
`game/cleanup_end`（整局结束或中止）、`reset/run`：
也就是说**关掉、重载、结束、重置都会让边界消失**，而**只有开局会让它出现**。

边界命令收的是正方形边长，书里写的是半径，`util/border_apply` 按档位映射成
`set 40 / 60 / 80 / 100 / 120 / 140 / 160 / 180 / 200`（即半径 × 2）——和 Boss 栏进度条一样，
参数是命令字面量、代入不了记分板，只能逐档分派。

`config/border_off` 会把尺寸与中心一起恢复成游戏的初始状态（直径 59999968、中心 0 0），
并读回一次实际直径显示在聊天栏，方便确认到底有没有生效。所有边界命令都写成
`execute in minecraft:overworld run ...`：这个命令只作用于**执行时所在的维度**，
而书里的按钮是玩家点的，不钉死维度就会跟着玩家跑。

**贴着边界的放置会被退回。** 世界边界的物理屏障按整方块取整，墙所在的那一格仍算圈内，
所以贴着墙能放下按钮、看着像放到圈外。`button/register_here` 在打完 `ybih_pending` 之后调用
`button/border_edge_check`：把按钮与集合点的坐标各乘 100 存进记分板（保留两位小数），
取 |Δx|、|Δz| 中较大的一个与「(真实半径 − 1) × 100」比较，超出就把 `#out_border` 置 1。
**真实半径由 `worldborder get` 读回**，不用书里选的档位值 —— 服主手动敲过 `/worldborder set` 时
两者会脱节，按档位判会在离墙很远的地方就误拒。取坐标失败时差值为 0、不会被判成越界，
**取向是宁可放行也不误杀**。
由 `button/border_reject` 退回材质、清掉方块与标记，并跳过后续的确认流程。

世界边界有几条来自查证的固有限制：

- **`/worldborder center` 只能设、不能读**（字节码里 `center` 后面是必填的 `pos`，没有无参查询），
  所以中心改成集合点之后**回不到原位置**；想保底就提前备份 `saves/<世界>/data/world_border.dat`。
  `get` 能读直径，但会四舍五入成整数。
- **圈外放不了也点不了按钮**——这条正好免费充当了藏匿范围限制，不用额外写代码。
- **边界本身是物理屏障**（“All entities are unable to move through the world border”），
  玩家走不出去。原版那条「圈外持续掉血」会被对局中的抗性提升免掉，所以拦住人的是墙、不是伤害；
  抗性对边界伤害到底免不免，**跨版本的确切行为尚未实测**。
- **`set` 的 `time` 参数在 1.21.11 从秒改成 tick**，不传 `time`（瞬间设置）即可绕开。
- **1.21.9 起边界每维度独立**，此前下界与主世界共用同一条。

### 可放置表面

`#ybih:placeable_surfaces` 为自建方块标签，含一份跨版本通用的常用方块表；
1.17 及以上还会并上原版 `#minecraft:mineable/axe`、`pickaxe`、`shovel`、`hoe`
（这几个标签 1.17 才加入，因此 1.16 必须自带基础表）。
引用原版标签的条目带 `"required": false`，缺失时自动跳过。

---

## 十二、跨版本写法对照

| 项 | 包 1 | 包 2 | 包 3 |
|---|---|---|---|
| 标记实体 | `armor_stand` + `Marker:1b` | 同左 | 同左 |
| 发放按钮 | `oak_button{CanPlaceOn:["#ybih:placeable_surfaces"],HideFlags:16}` | `oak_button[minecraft:can_place_on={predicates:[{blocks:"#ybih:placeable_surfaces"}]},minecraft:hide_additional_tooltip={}]` | `oak_button[minecraft:can_place_on={blocks:"#ybih:placeable_surfaces"},minecraft:tooltip_display={hidden_components:["minecraft:can_place_on"]}]` |
| 文本播报 | `{"text":"...","color":"gold"}` | 同左 | `{text:'...',color:'gold'}` |
| Boss 栏名字 | `[{"text":"第 "},{"score":{...}}]` | 同左 | `[{text:'第 '},{score:{...}}]` |
| 书页内容 | 字符串，内容是 JSON 数组 | 同左 | 组件本身（一页 = 一个组件列表） |
| 书页换行 | 文件里写 `\\n` | 同左 | 文件里写 `\n` |
| 函数目录 | `functions/` 与 `function/` 双份 | `functions/` 与 `function/` 双份 | `function/` |
| 标签目录 | `tags/blocks/` | `tags/blocks/` 与 `tags/block/` 双份 | `tags/block/` |
| 进度目录 | `advancements/` | `advancements/` 与 `advancement/` 双份 | `advancement/` |

### 隐藏「可放置在」提示行

客户端会把 `can_place_on` 里的方块标签**展开成全部方块名**列出，条目多时提示框会盖住物品名。
隐藏手段同样按版本分三段，与 `can_place_on` 自身的语法分界**并不重合**：

| 区间 | 写法 | 说明 |
|---|---|---|
| ≤ 1.20.4 | `HideFlags:16` | NBT 位标记。位 1 隐藏附魔提示，位 16 才是「可放置在」 |
| 1.20.5 – 1.21.4 | `minecraft:hide_additional_tooltip={}` | `HideFlags` 在此被拆成独立组件，本组件接管该职责 |
| 1.21.5+ | `minecraft:tooltip_display={hidden_components:["minecraft:can_place_on"]}` | `hide_additional_tooltip` 被移除，由 `tooltip_display` 按组件名精确隐藏 |

三段的验证范围不同：`tooltip_display`（包 3）在 1.21.11 与 26.2 上验过；
包 2 的 `hide_additional_tooltip={}` 只在 1.21.4 上做过独立 `/give` 悬停测试；
包 1 的 `HideFlags:16` 尚未单独确认。
`tooltip_display` 在 1.21.4 上**不存在**，
使用会报 `未知的物品组件 "minecraft:tooltip_display"`，因此不能提到包 2 使用。

三段写法集中在 `src/manifest.mjs` 的 `giveLegacy` / `giveComponentA` / `giveComponentB`，
`give_buttons`（发按钮）与 `button/refund_pending`（退还待放置按钮）共用同一生成器，改动一处两个函数同步生效。

---

## 十三、文件结构

```text
├── README.md                  # 安装与操作说明（面向玩家与服主）
├── LICENSE                    # MIT
├── ybih_memory.md             # 开发笔记：状态、决策、踩坑
├── ybih_test_checklist.txt    # 按版本分层的验收清单
├── ybih_design_doc.md         # 本文件
├── .github/workflows/release.yml  # 打 tag 时自动构建并发布 Release
├── .gitignore                 # 忽略 dist/ 等构建产物
├── tools/
│   ├── build.mjs              # 构建、静态校验与 zip 打包
│   └── verify_zips.py         # 产物校验（CRC 与结构）
├── src/
│   ├── manifest.mjs           # 3 个包的定义、选项函数、物品与文本语法
│   ├── book.mjs               # 设置书的文案与排版
│   ├── block_versions.mjs     # 方块 ID → 起始版本 对照表
│   └── data/
│       ├── minecraft/tags/function/{load,tick}.json
│       └── ybih/
│           ├── function/{load,tick,start,stop,reset}.mcfunction
│           ├── function/{game,turn,button,player,util,config,reset}/
│           ├── advancement/{button_placed,button_used}.json
│           └── tags/block/placeable_surfaces.json
└── dist/                      # 构建产物：3 个 zip（不入版本管理）
```

## 十四、zip 打包

构建在校验通过后，把每个包输出为 zip，**不留解压后的目录**：
先写到临时暂存目录，打包完成随即删除，因此 `dist/` 下只有 `.zip`。
打包是手写 ZIP 结构（`tools/build.mjs` 的 `zipDir`），不依赖第三方库，
因此有三个必须守住的不变量：

| 不变量 | 写错的后果 |
|---|---|
| 压缩必须是**裸 deflate**（`deflateRawSync`） | 用 `deflateSync` 会带上 zlib 头尾，ZIP method 8 不认，解压报 `ZIP decompression failed` |
| CRC-32 必须算**未压缩的原字节** | 算成压缩字节时，不校验 CRC 的解压器（资源管理器、`Expand-Archive`）能正常解出，但 `tar` 与 Python `zipfile.testzip()` 判定损坏 |
| `pack.mcmeta` 必须位于 zip **根部** | 多套一层目录游戏就读不到，表现为数据包列表里看不见 |

条目顺序上，**目录条目必须先于其内容写入**，否则解压器处理 `data/minecraft/xxx` 时父目录尚未建立。

校验不通过的包不会被打包，避免把坏产物封进 zip 分发。
验证 zip 健康度要用会校验 CRC 的工具，`Expand-Archive` 不足以作为判据 ——
`tools/verify_zips.py` 就是干这个的（CRC、`pack.mcmeta` 是否在根部、三个包是否齐全、
`dist/` 有没有非预期条目），本地与 CI 共用，发布前一跑即可。

`player/give_buttons`、`button/tag_material`、`button/tag_face`、`button/press_tick`、
`button/press_scan`、`button/protect_check`、`button/protect_restore`、`button/refund_pending`、
`util/clear_placed_blocks`、`admin/book`、`game/bar_value`、`game/showcase_view`、`game/showcase_pin`、
`game/hint_scan`、`button/fluid_check`
以及 `config/` 下的数值选项函数由构建脚本生成，不在源码中手工维护。
设置书的文案与排版在 `src/book.mjs`（行模型、页脚定位、三个包的渲染），
`src/manifest.mjs` 只做转出。

构建还会把每个包的 `waitRoomY` 注入源码里的 `{{WAIT_ROOM_Y}}` 占位符（高空等待室的基准高度）。

冷热提示的半径是**运行时可调设置**（`#hint_range`），档位表在 `src/book.mjs` 的 `HINT_RADII`：
`game/hint_scan` 里的扫描命令、以及书上的半径选项都由它生成，改一处两边一起变。
默认档 `HINT_RANGE_DEFAULT` 必须出现在档位表里，构建时会校验。

按功能分组的手写函数：

- **Boss 栏**：`game/bar_init`、`bar_show`、`bar_update`、`bar_hide`
- **物品栏提示**：`game/action_hint`（放置确认）、`game/hint_one`（冷热提示）
- **侧边栏镜像**：`game/board_sync`
- **轮末围观**：`game/showcase_begin`、`showcase_start`、`showcase_tick`、`showcase_step`、
  `showcase_pick`、`showcase_cmp`、`showcase_show`、`showcase_restore`、`showcase_bar`、
  `showcase_end`
  （观看站位由生成的 `showcase_view` 分派），开关是 `config/showcase_on` / `config/showcase_off`
- **围观高亮**：`game/showcase_glow`（配色与清场）、`showcase_glow_owner`（物主同色 + 挂标签）、
  `showcase_bar_owner`（把物主名字写进 Boss 栏标题）；两个队伍在 `load` 里建
- **饥饿与免伤**：`player/apply_buff`、`player/buff_guard`、`player/clear_buff`
- **高空等待室**：`util/build_wait_room`、`util/remove_wait_room`
- **活动边界**：`util/border_apply`、`util/border_reset`、`button/border_edge_check`、`button/border_reject`
- **按下归属**：`button/on_use`（进度奖励函数）、`button/use_ray` / `button/use_probe` / `button/use_lock`
  （锁定是哪一个按钮）、`button/press_claim`（裁决）、`button/release`（弹起解锁）
- **放置位置校验**：`button/register_ok`、`button/drop_unknown`、`button/confirm_place_ok`、
  `button/reject_unknown`、`button/drop_pending`
- **重连兜底**：`player/leave_room`

进度的触发器名由构建脚本按包注入 `{{USE_TRIGGER}}`：包 1 用 `item_used_on_block`，
包 2、3 用 `any_block_use`（原因见第七节「按下检测」）。

### 版本判断与白名单过滤

`src/block_versions.mjs` 维护「方块 ID → 起始版本」对照表（`BLOCK_SINCE`），
构建期据此把该包下限版本还不存在的方块从 `placeable_surfaces` 里滤掉，
并反过来校验源文件里有没有引用不该出现的方块。
未登记的一律按 1.16 起就有处理。

`versionAtLeast(a, b)` 比较两个版本串。**比较前要把段数补齐**：
`'1.16'` 只有两段，直接解构出的第三段是 `undefined`，
与 `'1.16.2'` 相比时 `2 > undefined` 会得到 `false`，
把本该保留的方块全部滤掉（包 1 白名单会从 94 条掉到 4 条）。
现在缺段一律当 0，即 `'1.16'` == `[1, 16, 0]`。

改过任何包的 `minVersion` 之后，除了看构建退出码，还要核对白名单条目数：
包 1 为 94 条（90 个方块 + 4 个 `#minecraft:mineable/*` 标签），包 2/3 为 102 条。
构建校验只查「引用了不存在的方块」，查不出「存在的方块被判成不存在」。

### 构建产物的清理

`tools/build.mjs` 每次构建会清掉 `dist/` 下一切不属于当前三个包的东西 ——
目录与 zip 都清，判据是「名字不等同于 `<包 id>.zip`」。
所以改过包 `id`（改名、拆并包）之后，旧名字的产物不会留在 `dist/` 里被误当成新产物部署出去。
