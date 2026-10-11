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

# 这是不是这个按钮**第一次**被找到 —— 物主的保底分会不会因这次按下作废，就看它。
# **必须在位图写入之前读**（位图由 award_pay 落，写进去之后 hit 就不是 0 了）。
#
# 判据是 hit 全零，不能用 #hit_now（那是 hit 对本位取模的结果）：#hit_now == 0
# 只能说明「本位没置过」，先按的人编号更大时（例如 id=5 先按、id=2 后按，
# 16 % 4 == 0）会误判成没人按过，于是第 2 个人按下时也发「保底分没了」
scoreboard players set #first_find ybih.config 0
scoreboard players set #hit_all ybih.config -1
execute if score #deny ybih.config matches 0 run scoreboard players operation #hit_all ybih.config = @e[tag=ybih_active,limit=1] ybih.hit
execute if score #deny ybih.config matches 0 if score #hit_all ybih.config matches 0 run scoreboard players set #first_find ybih.config 1

execute if score #deny ybih.config matches 0 run function ybih:button/award_pay
execute if score #deny ybih.config matches 1.. run function ybih:button/award_deny
