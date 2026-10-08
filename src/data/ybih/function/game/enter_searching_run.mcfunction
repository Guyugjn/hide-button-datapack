# ybih:game/enter_searching_run —— 搜寻阶段初始化

# 藏匿阶段一结束，等待室里的棋局就没有意义了：棋盘作废、位子让出来，
# 人随后会被 enter_searching_* 送回集合点，残局不会跟着进搜寻阶段
function ybih:room/ttt_reset

scoreboard players set #state ybih.config 3
scoreboard players operation #timer ybih.config = #search_time ybih.config
scoreboard players operation #hint_timer ybih.config = #hint_period ybih.config
scoreboard players set #actionbar_timer ybih.config 20

# 进入搜寻 —— 关键节点：搜寻者必须能按按钮，一律按回冒险模式。
# 模式在节点之间是自由的，他可能自己切成了旁观或创造；旁观按不了按钮，这里按回来。
# 要排在下面两条分派之前：轮流模式的藏匿者随后会被 enter_searching_rotate 切回旁观，
# 那是设计要的观战身份，不是被这里漏掉
execute as @a[tag=ybih_player,gamemode=!adventure] run tellraw @s {{TXT_S}}搜寻开始，已把你切回冒险模式{{TXT_M}}gray{{TXT_E}}
execute as @a[tag=ybih_player] run gamemode adventure @s

execute if score #mode ybih.config matches 1 run function ybih:game/enter_searching_classic
execute if score #mode ybih.config matches 2 run function ybih:game/enter_searching_rotate

# 最后一位确认藏匿时直接落到这里，同样不经过每秒循环
function ybih:game/bar_update
