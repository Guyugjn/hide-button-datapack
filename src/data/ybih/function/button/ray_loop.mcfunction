# ybih:button/ray_loop —— 每步前进 0.1 格、最多 40 步（4 格），每步探测当前格与 6 个邻格
# 按钮由原版放在被点方块的邻格里，而非完整方块（半砖、楼梯、活板门）的命中点在方块内部，
# 视线射线不会经过按钮所在的那一格，所以必须顺带探测邻格才能找到它

scoreboard players add #ray_step ybih.config 1
execute unless entity @s[tag=ybih_ray_found] run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~1 ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~-1 ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~1 ~ ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~-1 ~ ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~1 run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~-1 run function ybih:button/probe_here
execute if score #ray_step ybih.config matches ..39 unless entity @s[tag=ybih_ray_found] positioned ^ ^ ^0.1 run function ybih:button/ray_loop
