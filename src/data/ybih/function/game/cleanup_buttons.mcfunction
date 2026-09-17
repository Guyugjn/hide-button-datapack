# ybih:game/cleanup_buttons —— 清除本轮按钮与状态（轮间使用，不动玩家身份）
# 轮流模式的藏匿者在搜寻期是旁观，先送回集合点再切回冒险，避免切回时卡在方块里

function ybih:util/cleanup_all
tag @a remove ybih_pressed
execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]
gamemode adventure @a[tag=ybih_current]
effect clear @a[tag=ybih_current] minecraft:night_vision
tag @a remove ybih_current
scoreboard players set @a ybih.trigger 0
