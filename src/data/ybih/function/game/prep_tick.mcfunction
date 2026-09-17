# ybih:game/prep_tick —— 准备阶段

scoreboard players remove #actionbar_timer ybih.config 1
execute if score #actionbar_timer ybih.config matches ..0 run function ybih:game/second_tick
