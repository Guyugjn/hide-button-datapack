# ybih:button/use_probe_nbrs —— 探当前格的 6 个邻格，找本局的按钮标记
# 只由 button/use_ray_nbr（按下定位射线的第二遍）调用。与 button/probe_nbrs 对称，
# 差别只在调用的探针：那边是放置用的 probe_here，这边是按下用的 use_probe
#
# 执行者是射线发起玩家，use_probe 命中后交给 use_lock 锁定编号并停止射线

execute unless entity @s[tag=ybih_ray_found] positioned ~ ~1 ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~-1 ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~1 ~ ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~-1 ~ ~ run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~1 run function ybih:button/use_probe
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~-1 run function ybih:button/use_probe
