# ybih:game/cleanup_buttons —— 清除本轮按钮与状态（轮间使用，不动玩家身份）
# 这个文件只清场，不改任何人的游戏模式 —— 模式在节点之间是自由的，
# 玩家自己换的模式由他自己负责。唯一在这里收尾的是数据包自己安排的那份身份：
# 轮流模式的藏匿者在搜寻期被切成旁观，本轮结束就该交还（见下面那三条）。
# 整局结束时的还原由 cleanup_end / reload_cleanup / reset 按 ybih_gm_* 记录做

function ybih:util/cleanup_all
tag @a remove ybih_pressed
# 轮流模式的藏匿者在搜寻期是旁观，先送回集合点：旁观可以飞进方块内部，
# 直接在原地恢复模式会卡在方块里窒息。上面的还原排在这一步之后
execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]
# 交还数据包安排的那份观战身份：本轮结束时，凡是「参与者、当前是旁观、且身上有原模式记录」
# 的人一律按记录还原。轮末是节点，节点上强制一次；节点之间才由玩家自己说了算。
#
# 覆盖面比只认 ybih_current 更宽，是因为藏匿者可能在本轮中途掉线、重连时已被换人：
# 那种情况下 game/current_clear 会先摘掉他的凭据，等轮末再按 ybih_current 找就找不到他，
# 他会一直停在旁观 —— 每 tick 强推已经取消，再没有别人把他拉回冒险。
# 代价是「本轮自己主动切成旁观的参与者」也会在这一刻被拉回冒险，他再切回去即可。
#
# 三条都带 gamemode=spectator 前置，先命中的那条会把玩家切出旁观、后面的不再命中，
# 所以「身上至多只有一个 ybih_gm_*」是这里正确性的前提
execute as @a[tag=ybih_player,gamemode=spectator,tag=ybih_gm_creative] run gamemode creative @s
execute as @a[tag=ybih_player,gamemode=spectator,tag=ybih_gm_survival] run gamemode survival @s
execute as @a[tag=ybih_player,gamemode=spectator,tag=ybih_gm_adventure] run gamemode adventure @s
effect clear @a[tag=ybih_current] minecraft:night_vision
tag @a remove ybih_current
scoreboard players set @a ybih.trigger 0
