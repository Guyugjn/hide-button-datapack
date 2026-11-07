# ybih:button/award_score —— 位图已落，正式计分
# 执行者是按下者，#gained 是这次拿到的分，#first_find 标记这是不是这个按钮第一次被找到
#
# #first_find 由 award_grant 在读到位图之前判好，这里只消费它，不重算。

scoreboard players operation @s ybih.score += #gained ybih.config
scoreboard players add @s ybih.finds 1
execute if score @s ybih.finds matches 1 run scoreboard players operation @s ybih.t_first = #tick ybih.config
playsound minecraft:entity.player.levelup player @a ~ ~ ~ 1 1.5

tellraw @s [{{TXT_S}}+{{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}green{{TXT_E}}]
function ybih:button/press_broadcast
# 物主的保底分因这一次按下作废或减半 —— 这是藏匿方判断「这次藏成没成」的主要反馈。
# 半档必须先算：notify_first_find 要读 #bonus_half 才知道该说「全没」还是「减半」，
# 顺序反了它读到的是上一次留下的旧值
execute if score #first_find ybih.config matches 1 if score #timer ybih.config <= #late_from ybih.config run function ybih:button/bonus_half
execute if score #first_find ybih.config matches 1 run function ybih:button/notify_first_find
function ybih:button/award_dec
