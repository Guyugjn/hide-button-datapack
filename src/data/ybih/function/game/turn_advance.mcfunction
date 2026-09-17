# ybih:game/turn_advance —— 推进到下一回合，或结束藏匿阶段

execute if score #mode ybih.config matches 1 if entity @a[tag=ybih_player,scores={ybih.turn=0}] run function ybih:game/turn_next
execute if score #mode ybih.config matches 1 unless entity @a[tag=ybih_player,scores={ybih.turn=0}] run function ybih:game/enter_searching
execute if score #mode ybih.config matches 2 run function ybih:game/enter_searching
