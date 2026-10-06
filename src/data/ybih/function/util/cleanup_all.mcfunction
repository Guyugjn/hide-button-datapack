# ybih:util/cleanup_all —— 清除所有对局实体、按钮方块与物品

# 围观展示要等展示走完（game/showcase_end）才会把按钮收回世界。
# /reload、重置、换局都可能落在展示半途，这时候标记带着 ybih_showcase，方块还在世界里。
# 下面两条 kill 必须排在这次清扫之后，理由有两条，缺一条就会留下野按钮：
#   1) 展示标记里混着 ybih_ghost —— 被按掉的按钮在展示时会临时放回原位，
#      第 12 行一 kill，那些方块就再也没人认领，永远留在世界里。这正是
#      「结尾围观按钮时 reload 不会清除放置的按钮」的直接原因。
#   2) 展示标记里也混着 ybih_button，第 9 行会先 kill 掉它们，
#      util/clear_placed_blocks 只按 ybih_button 找方块，同样会漏。
# 还要排在 forceload remove 之前：区块强加载一撤，这些格子可能已经不在加载范围内，
# setblock 会静默失败，方块照样留下（同一 tick 内一般还来得及，但不值得赌）
execute as @e[tag=ybih_showcase] at @s if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ air

# 申请过区块强加载的标记，必须在被 kill 之前先释放，否则那些区块会被永久钉住
# （标记一没，后面任何 forceload remove 都再也选不中它们）
execute as @e[tag=ybih_pinned] at @s run forceload remove ~ ~
tag @e[tag=ybih_pinned] remove ybih_pinned

# 强加载已按 ybih_pinned 释放过，这里才轮到把展示标记本身收掉
kill @e[tag=ybih_showcase]

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
