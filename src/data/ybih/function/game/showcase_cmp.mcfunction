# ybih:game/showcase_cmp —— 求最小藏匿编号（执行者是还没展示过的标记之一）
# #show_best 只减不增，扫完全部标记后它就是最小的那个编号
# 编号缺失（0）的当成最小：那种标记本来就选不出站位，先跳过它反而卡住队列

# 编号小的顶替上来。写成「候选 < 当前最优」而不是「最优 > 候选」，
# 因为 if score 的左边必须是分数持有者，右边才能是持有者或区间
execute if score @s ybih.seq < #show_best ybih.config run scoreboard players operation #show_best ybih.config = @s ybih.seq
