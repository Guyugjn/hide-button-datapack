# ybih:game/showcase_pick —— 从还没展示过的标记里挑一个
# 挑不中也不影响计时：编号照样往下走，最多空等一轮就收尾
#
# 按藏匿先后挑：取编号最小的那个。不用 sort=nearest —— 这条链从头到尾没有执行实体，
# 排序的参考点会退化成命令原点（世界原点），顺序就成了「离原点由近到远」，
# 隔着几百格来回绕，观感上像乱跳
#
# 「最小且未展示」没有现成的排序参数，用两趟自己求最小值：
# 第一趟把每个候选的编号折进 #show_best（取小），第二趟谁等于它谁上场
#
# 候选取空时用 #c_max 当哨兵：等于它说明一个都没扫到
scoreboard players operation #show_best ybih.config = #c_max ybih.config
execute as @e[tag=ybih_showcase,tag=!ybih_shown] run function ybih:game/showcase_cmp
execute unless score #show_best ybih.config = #c_max ybih.config as @e[tag=ybih_showcase,tag=!ybih_shown] if score @s ybih.seq = #show_best ybih.config run function ybih:game/showcase_show
