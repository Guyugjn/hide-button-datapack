# ybih:game/classic_next —— 经典模式：本轮之后续轮还是收官
# 先判定再执行：next_round 会把 #round 加一，不能在同一函数里顺着再判一次

scoreboard players set #more ybih.config 0
execute if score #round ybih.config < #rounds_total ybih.config run scoreboard players set #more ybih.config 1
execute if score #more ybih.config matches 1 run function ybih:game/next_round
execute if score #more ybih.config matches ..0 run function ybih:game/final_summary
