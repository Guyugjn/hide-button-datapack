# ybih:game/searching_tick —— 搜寻阶段计时
# 在线未领取份数与收官由 dynamic_monitor 在主循环中检查。

scoreboard players remove #actionbar_timer ybih.config 1
execute if score #actionbar_timer ybih.config matches ..0 run function ybih:game/second_tick
