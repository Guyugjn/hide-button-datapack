# ybih:tick —— 主循环

execute if score #state ybih.config matches 1..3 run scoreboard players add #tick ybih.config 1

# 右侧榜单：每秒对一次在线名单（有人进出就整榜重建），分数每 tick 增量同步。
# 重建要排在同步前面，这样清掉的榜在同一 tick 内就会被在线的人重新填上
scoreboard players remove #board_timer ybih.config 1
execute if score #board_timer ybih.config matches ..0 run function ybih:game/board_sync
execute as @a unless score @s ybih.board = @s ybih.score run scoreboard players operation @s ybih.board = @s ybih.score

execute if score #state ybih.config matches 1 run function ybih:game/prep_tick
execute if score #state ybih.config matches 2 run function ybih:game/turn_tick
execute if score #state ybih.config matches 3 run function ybih:game/searching_tick
execute if score #state ybih.config matches 4 run function ybih:game/showcase_tick

execute as @a run function ybih:player/on_join
execute as @a[scores={ybih.death=1..}] run function ybih:player/on_death

execute if score #state ybih.config matches 3 run function ybih:button/press_tick
execute as @a[scores={ybih.trigger=1..}] run function ybih:button/trigger_run

scoreboard players remove #protect_timer ybih.config 1
execute if score #protect_timer ybih.config matches ..0 if score #state ybih.config matches 1..3 run function ybih:button/protect_tick

# 对局保险：死亡、牛奶或外部 /effect clear 都会把效果抹掉，而标记还在，每秒顶回去一次。
# 不受 #state 限制 —— 效果要挂到下一次 /reload 为止，对局结束后照样保持
scoreboard players remove #buff_timer ybih.config 1
execute if score #buff_timer ybih.config matches ..0 run function ybih:player/buff_guard
