# ybih:game/enter_searching_run —— 搜寻阶段初始化

scoreboard players set #state ybih.config 3
scoreboard players operation #timer ybih.config = #search_time ybih.config
scoreboard players operation #hint_timer ybih.config = #hint_period ybih.config
scoreboard players set #actionbar_timer ybih.config 20

execute if score #mode ybih.config matches 1 run function ybih:game/enter_searching_classic
execute if score #mode ybih.config matches 2 run function ybih:game/enter_searching_rotate

# 最后一位确认藏匿时直接落到这里，同样不经过每秒循环
function ybih:game/bar_update
