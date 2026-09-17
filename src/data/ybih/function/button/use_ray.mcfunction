# ybih:button/use_ray —— 沿视线每步前进 0.1 格、最多 40 步（4 格），找到对着的按钮标记
# 每步探「当前格 + 上下前后左右 6 邻格」：按钮由原版放在被点方块的邻格里，
# 而非完整方块（半砖、楼梯、活板门）的命中点在方块内部，视线射线不会经过按钮那一格，
# 必须顺带探邻格才能找到它 —— 与 button/ray_loop 是同一个坑
#
# 只认本局登记的按钮（ybih_era 对得上）、且不是待确认的：
# 地图自带的按钮、往局残留、玩家刚放还没确认的都不参与按下判定
# 命中后把该标记的编号抄进玩家的 ybih.used_bid，press_scan 靠它认领

scoreboard players add #ray_step ybih.config 1
execute unless entity @s[tag=ybih_ray_found] run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~1 ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~-1 ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~1 ~ ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~-1 ~ ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~1 run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~-1 run function ybih:button/use_probe
execute if score #ray_step ybih.config matches ..39 unless entity @s[tag=ybih_ray_found] positioned ^ ^ ^0.1 run function ybih:button/use_ray
