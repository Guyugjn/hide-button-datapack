# ybih:button/use_ray_nbr —— 按下定位射线的第二遍：在每个「有方块」的采样格探它的 6 个邻格
#
# 只在第一遍（button/use_ray，只认射线正中的那一格）走满 60 步仍没锁到按钮时才跑。
# 与放置侧 button/ray_loop_nbr 是同一套设计与同一段理由，改动务必两边同步：
# 第一遍只探射线上的格子，凭的是「射线上、目标之前的格子若已有本局按钮，
# 客户端准星会先选中它、这次右键被它吃掉」——所以第一遍不可能锁错按钮。
# 每步都探邻格就没有这层保护，邻格会扫进大量不在射线上的格子，
# 那儿的本局按钮会被抢先锁走，表现成「点的是这个、加分算在那个上」。
#
# 长度与 pause 侧完全一致：这一遍也是独立的 60 步（6 格），
# 由 button/on_use_trace 把 #ray_step 归零后重新从眼位出发

scoreboard players add #ray_step ybih.config 1
execute unless entity @s[tag=ybih_ray_found] unless block ~ ~ ~ air unless block ~ ~ ~ cave_air unless block ~ ~ ~ void_air run function ybih:button/use_probe_nbrs
execute if score #ray_step ybih.config matches ..59 unless entity @s[tag=ybih_ray_found] positioned ^ ^ ^0.1 run function ybih:button/use_ray_nbr
