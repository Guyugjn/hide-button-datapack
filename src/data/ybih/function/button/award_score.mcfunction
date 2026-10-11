# ybih:button/award_score —— 位图已落，正式计分
# 执行者是按下者，#gained 是这次拿到的分，#first_find 标记这是不是这个按钮第一次被找到
#
# #btn_remain 要在这里算：它表示「这次取走后还剩几份」，而 award_dec 的递减排在最后，
# 那一刻读 #btn_left 已经太晚（播报里要说的是递减之后的余额）。
# 此处 ybih.value 还是按下瞬间的值，减 1 就是余额。
# #first_find 由 award_grant 在读到位图之前判好，这里只消费它，不重算

scoreboard players operation @s ybih.score += #gained ybih.config
scoreboard players add @s ybih.finds 1
execute if score @s ybih.finds matches 1 run scoreboard players operation @s ybih.t_first = #tick ybih.config
playsound minecraft:entity.player.levelup player @a ~ ~ ~ 1 1.5

scoreboard players operation #btn_remain ybih.config = @e[tag=ybih_active,limit=1] ybih.value
scoreboard players remove #btn_remain ybih.config 1

tellraw @s [{{TXT_S}}+{{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}green{{TXT_E}}]
function ybih:button/press_broadcast
# 物主的保底分因这一次按下作废，单独告诉他 —— 这是藏匿方判断「这次藏成没成」的主要反馈
execute if score #first_find ybih.config matches 1 run function ybih:button/notify_first_find
function ybih:button/award_dec