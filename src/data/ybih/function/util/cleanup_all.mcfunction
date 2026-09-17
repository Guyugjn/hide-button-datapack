# ybih:util/cleanup_all —— 清除所有对局实体、按钮方块与物品

# 申请过区块强加载的标记，必须在被 kill 之前先释放，否则那些区块会被永久钉住
# （标记一没，后面任何 forceload remove 都再也选不中它们）
execute as @e[tag=ybih_pinned] at @s run forceload remove ~ ~
tag @e[tag=ybih_pinned] remove ybih_pinned

function ybih:util/clear_placed_blocks
kill @e[tag=ybih_button]
# 被按掉的按钮只剩一条记录，方块早就没了。换局、重置、重载都要连它一起收，
# 否则它会一直留在世界里等下一次围观，甚至被下一局的展示选中
kill @e[tag=ybih_ghost]
kill @e[tag=ybih_new]
# 旧版本留下的等待点标记可能还在老存档里，连它申请过的区块强加载一起撤掉
execute at @e[tag=ybih_wait] run forceload remove ~ ~
kill @e[tag=ybih_wait]
scoreboard players set #button_count ybih.config 0
clear @a #minecraft:buttons
