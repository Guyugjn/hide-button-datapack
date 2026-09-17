# ybih:game/searching_tick —— 搜寻阶段
# 经典模式按剩余按钮数结束；轮流模式按还没找到的搜寻者数结束

scoreboard players remove #actionbar_timer ybih.config 1
execute if score #actionbar_timer ybih.config matches ..0 run function ybih:game/second_tick
execute if score #mode ybih.config matches 1 if score #button_count ybih.config matches ..0 run function ybih:game/end_round
execute if score #mode ybih.config matches 2 if score #seekers_left ybih.config matches ..0 run function ybih:game/end_round
