# ybih:game/points_tally —— 累计这一个按钮的分值，并在它「一次都没被找到过」时计数
# 执行者是按钮标记，由 game/points_count 逐个调进来，本局筛选已在调用方做完
#
# 两个量在**同一次遍历**里数出来，就是为了省掉第二次 as @e：
# 逐实体逻辑走「一次遍历 + 内部廉价分派」是本项目的约定（见设计文档），
# 每秒一次的两趟全服实体遍历没有理由留着
#
# 判据是 ybih.hit 全零，与 game/bonus_run 同源：hit 是位图，
# 全零才代表没有任何人从这个按钮上取过分。
# 不看 ybih.value —— 被按过一次的按钮 value 仍大于 0，两种情形分不开

scoreboard players operation #points_left ybih.config += @s ybih.value
execute if score @s ybih.hit matches 0 run scoreboard players add #unfound_count ybih.config 1
