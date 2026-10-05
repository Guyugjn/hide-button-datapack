# ybih:game/cleanup_buttons —— 清除本轮按钮与状态（轮间使用，不动玩家身份）
# 这个文件只清场，不改任何人的游戏模式。恢复模式由两个地方各管一段：
#   · 对局还在继续时 —— player/active_state 每 tick 把非藏匿者的参与者拉回冒险；
#   · 整局结束时 —— cleanup_end / reload_cleanup 按 ybih_gm_* 记录还原各人本来的模式。
# 清场工具替玩家决定模式会同时盖掉这两处：前者一秒后能自己纠正，
# 后者的三条还原都带 gamemode=spectator 前置，被切走之后就再也命不中

function ybih:util/cleanup_all
tag @a remove ybih_pressed
# 轮流模式的藏匿者在搜寻期是旁观，先送回集合点：旁观可以飞进方块内部，
# 直接在原地恢复模式会卡在方块里窒息。上面那两处恢复点都排在这一步之后
execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]
effect clear @a[tag=ybih_current] minecraft:night_vision
tag @a remove ybih_current
scoreboard players set @a ybih.trigger 0
