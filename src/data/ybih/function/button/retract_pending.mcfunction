# ybih:button/retract_pending —— 收回一个待确认的按钮：清掉方块再删除标记（以标记为执行者）

execute at @s if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ minecraft:air
kill @s
