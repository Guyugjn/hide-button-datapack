# ybih:button/probe_here —— 当前位置是不是刚放下的按钮（已登记过的不算）
#
# 判定位置要先落到方块中心：射线位置是浮点，标记却精确在格中心，光 y 上就差约 0.62
# （眼高 1.62，标记贴着方块底）。拿浮点位置去比 ..0.5，连同一格的标记都认不出来，
# 隔壁那个已经登记过的按钮会被当成「还没登记」而重复召唤标记。
# 对齐之后同格距离 0、邻格 1.0，闸门才分得开；下面的 register_here 与它之后各步
# 也都以这个格中心为执行位置，那些 ..2 的查询随之不再有歧义

execute align xyz positioned ~0.5 ~ ~0.5 if block ~ ~ ~ #minecraft:buttons unless entity @e[tag=ybih_button,distance=..0.5] run function ybih:button/register_here
