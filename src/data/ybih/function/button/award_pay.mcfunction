# ybih:button/award_pay —— 落位图、计分、递减
# 执行者是按下者，#gained 是按下瞬间读到的按钮分值
#
# 位图那条写入同时充当成败探针：它写不进去说明按钮标记在识别与结算之间被清掉了。
# 这一步排在计分之前，探针没过就一分不动、也没置位，玩家可以原地再按一次

scoreboard players set #hit_ok ybih.config 0
execute store success score #hit_ok ybih.config run scoreboard players operation @e[tag=ybih_active,limit=1] ybih.hit += #hit_bit ybih.config
execute if score #hit_ok ybih.config matches 0 run function ybih:button/award_retry
execute if score #hit_ok ybih.config matches 1 run function ybih:button/award_score
