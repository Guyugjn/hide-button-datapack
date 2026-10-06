# ybih:button/ray_loop_nbr —— 放置定位射线的第二遍：在每个「有方块」的采样格探它的 6 个邻格
#
# 只在第一遍（button/ray_loop，只认射线正中的那一格）走满 60 步仍没认出按钮时才跑。
# 第一遍覆盖绝大多数放置（几何复现 1440 个场景里 96.9%），剩下 3.1% 是采样点整格跳过
# 按钮格的情形 —— 射线贴着方块棱角擦过，穿过按钮格的那一段弦极短，0.1 格的步长跨了过去。
# 只有邻格探测能把它捞回来：加上这一遍后复现里 1440/1440 全部找到。
#
# 这一遍的候选面靠「当前格必须有方块」收窄。判据是 `unless block ~ ~ ~ air` 一族而不是
# 「是不是实心方块」：原版在 1.16.2 没有「是完整方块」这种谓词，而 air / cave_air / void_air
# 是三个独立方块，三个都要排除，漏一个就会把洞穴与虚空里的空气当成障碍、在空处白开门。
# 门开在「任何有方块的格」上，比开在「射线确实钻进了那个方块」上更宽一点，
# 但按钮格 P 只会是被点方块的面邻格，而射线必然从被点方块里穿过，
# 所以这一遍一定覆盖得到 P；反过来在射线抵达被点方块之前，门在别的非空气格上开也无妨 ——
# 那一带正是射线本身经过的地方，上面的格子受「准星会先命中它」保护，野按钮抢不走。
#
# 为什么不把这六行并回第一遍：并回去就等于每一步都探邻格，而邻格会扫进大量不在射线上的格子。
# 复现量出那样做的离轴候选面平均 11.4 格、最多 23 格，野按钮落在那儿就会被误登记；
# 只让它在 3.1% 的场景里跑，同一指标降到 0.03 格、最多 4 格

scoreboard players add #ray_step ybih.config 1
execute unless entity @s[tag=ybih_ray_found] unless block ~ ~ ~ air unless block ~ ~ ~ cave_air unless block ~ ~ ~ void_air run function ybih:button/probe_nbrs
execute if score #ray_step ybih.config matches ..59 unless entity @s[tag=ybih_ray_found] positioned ^ ^ ^0.1 run function ybih:button/ray_loop_nbr
