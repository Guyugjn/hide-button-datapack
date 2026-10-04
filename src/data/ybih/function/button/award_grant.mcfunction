# ybih:button/award_grant —— 从别人的按钮上取走一份分
# 执行者是本次的按下者，被按下的按钮由 ybih_active 标出
#
# 每人每个按钮只算一次：按钮标记上的 ybih.hit 是位图，位号 = 玩家编号 - 1，
# 取模判定这一位有没有置过。已经在里面的人再按不给分，只提示
#
# 拒绝的理由先记进 #deny 再统一播报，免得每条分支各写一遍提示：
#   1 编号超出位图上限（记不下就没法去重，宁可拒掉也不能重复计分）
#   2 这位玩家已经从这个按钮上拿过
#   3 这个按钮的分已经拿完
#   4 按钮标记已经不在了

scoreboard players set #deny ybih.config 0
scoreboard players set #hit_bit ybih.config 0
scoreboard players set #hit_pow ybih.config 0
scoreboard players set #hit_now ybih.config 0
execute unless entity @e[tag=ybih_active,limit=1] run scoreboard players set #deny ybih.config 4
execute if score #deny ybih.config matches 0 run function ybih:button/hit_bit
execute if score #deny ybih.config matches 0 if score #hit_bit ybih.config matches ..0 run scoreboard players set #deny ybih.config 1

execute if score #deny ybih.config matches 0 run scoreboard players operation #hit_now ybih.config = @e[tag=ybih_active,limit=1] ybih.hit
execute if score #deny ybih.config matches 0 run scoreboard players operation #hit_now ybih.config %= #hit_pow ybih.config
execute if score #deny ybih.config matches 0 if score #hit_now ybih.config >= #hit_bit ybih.config run scoreboard players set #deny ybih.config 2

scoreboard players operation #gained ybih.config = @e[tag=ybih_active,limit=1] ybih.value
execute if score #deny ybih.config matches 0 if score #gained ybih.config matches ..0 run scoreboard players set #deny ybih.config 3

execute if score #deny ybih.config matches 0 run function ybih:button/award_pay
execute if score #deny ybih.config matches 1.. run function ybih:button/award_deny
