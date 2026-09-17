# ybih:game/showcase_tick —— 围观阶段的计时与 Boss 栏
# 围观期间 second_tick 不跑，Boss 栏的刷新只能由这里自己负责

scoreboard players remove #show_timer ybih.config 1
scoreboard players remove #show_refresh ybih.config 1

# 刚传送完的那一秒里每 tick 把大家按回站位，压掉「还按着方向键」造成的飘移。
# 只设位置、不带角度，玩家这一秒里仍然可以自由转视角看周围
scoreboard players remove #freeze ybih.config 1
execute if score #freeze ybih.config matches 1.. as @e[tag=ybih_showing,limit=1] run function ybih:game/showcase_pin

# 进度条跟着这一个按钮的剩余停留时间走
scoreboard players operation #pct ybih.config = #show_timer ybih.config
scoreboard players operation #pct ybih.config *= #c100 ybih.config
scoreboard players operation #pct ybih.config /= #show_len ybih.config
execute if score #pct ybih.config matches ..0 run scoreboard players set #pct ybih.config 0
function ybih:game/bar_value

# 标题每秒重写一次，剩余秒数才看得出在走
execute if score #show_refresh ybih.config matches ..0 run function ybih:game/showcase_bar

execute if score #show_timer ybih.config matches ..0 run function ybih:game/showcase_step
