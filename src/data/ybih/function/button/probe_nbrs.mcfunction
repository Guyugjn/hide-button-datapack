# ybih:button/probe_nbrs —— 探当前格的 6 个邻格，找刚放下的按钮
# 只由 button/ray_loop_nbr（放置射线的第二遍）调用，执行位置就是那个非空气格。
#
# 单独写成一个函数而不是并进探针循环里，是为了让「探正格」与「探邻格」两条路径
# 在代码上分开：第一遍 button/ray_loop 里出现的只有 probe_here，一眼就能看出它不碰邻格。
# 这正是本次要守的性质 —— 邻格探测会扫进不在射线上的格子，那些格子没有
# 「准星会先命中它」这层保护，野按钮落在那儿就会被抢走登记

execute unless entity @s[tag=ybih_ray_found] positioned ~ ~1 ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~-1 ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~1 ~ ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~-1 ~ ~ run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~1 run function ybih:button/probe_here
execute unless entity @s[tag=ybih_ray_found] positioned ~ ~ ~-1 run function ybih:button/probe_here
