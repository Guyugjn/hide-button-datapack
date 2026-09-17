# ybih:game/second_tick —— 每秒触发一次：推进计时、判定阶段、刷新显示

scoreboard players set #actionbar_timer ybih.config 20

execute if score #state ybih.config matches 1 run scoreboard players remove #timer ybih.config 1
execute if score #state ybih.config matches 2 run scoreboard players remove #hide_timer ybih.config 1
execute if score #state ybih.config matches 3 run scoreboard players remove #timer ybih.config 1
execute if score #state ybih.config matches 3 run scoreboard players remove #hint_timer ybih.config 1

function ybih:game/action_hint

execute if score #state ybih.config matches 3 if score #hint_timer ybih.config matches ..0 run function ybih:game/hint_all
execute if score #state ybih.config matches 1 if score #timer ybih.config matches ..0 run function ybih:game/enter_turn
execute if score #state ybih.config matches 2 if score #hide_timer ybih.config matches ..0 run function ybih:game/turn_timeout
execute if score #state ybih.config matches 3 if score #timer ybih.config matches ..0 run function ybih:game/end_round

# 阶段判定之后再刷 Boss 栏，切换阶段时标题不会慢一拍
execute if score #state ybih.config matches 1..3 run function ybih:game/bar_update

# 搜寻阶段别把重连回来的人关在等待室里
execute if score #state ybih.config matches 3 as @a[tag=ybih_player,tag=!ybih_current] run function ybih:player/leave_room
