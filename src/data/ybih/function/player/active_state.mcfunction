# ybih:player/active_state —— 对局中的每 tick 自省：补对局保险、把中途进来的旁观者接管一次
#
# 游戏模式不再每 tick 强推。玩家自己换的模式一律留给他，数据包只在关键节点动手：
#   · 入队            player/join_game         → 冒险
#   · 轮到你藏        game/turn_next           → 冒险
#   · 进入搜寻        game/enter_searching_*   → 搜寻者冒险，轮流模式的藏匿者旁观
#   · 轮末围观        game/showcase_start      → 全员旁观
#   · 死亡重生        player/on_death          → 冒险
# 节点之间是自由的：其中切到创造或旁观由玩家自己负责，数据包不回收也不纠正。
# 代价写在 README 与设计文档里：等待室的防偷看、搜寻阶段的公平都只靠节点那一刻维持

# 入队的人不一定领到过对局保险：game/start_begin 只在开局那一 tick 给全体发一次，
# 中途补进对局的人（game/next_round 调 player/join_game）赶不上那一趟，
# 而 player/buff_guard 只对已带 ybih_buffed 的人续期，发不出第一份。
# 这里每 tick 自省一次补上；掉线重连的人错过的也正是这一份
execute if entity @s[tag=ybih_player] unless entity @s[tag=ybih_buffed] run function ybih:player/apply_buff

# 对局中进来的非参赛者：转旁观、给夜视、送到观战位 —— 只做一次。
# 凭据 ybih_spec_once 记下「已经接管过」，他之后自己切回生存也不再插手，
# 否则每 tick 都会把他拽回旁观，等于他没得选。
# 三条前提缺一不可：已经是旁观的人不需要接管（服主自己设的旁观也走不到这里）
execute unless entity @s[tag=ybih_player] unless entity @s[tag=ybih_spec_once] unless entity @s[gamemode=spectator] run function ybih:player/spectate
