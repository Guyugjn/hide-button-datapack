# ybih:turn/reset —— 重置藏匿回合状态
# 经典模式每轮重置 turn（谁还没藏）；轮流模式 turn 表示本周期是否已藏，只在周期轮完时归零

scoreboard players set @a[tag=ybih_player] ybih.placed 0
scoreboard players set @a[tag=ybih_player] ybih.found 0
execute if score #mode ybih.config matches 1 run scoreboard players set @a[tag=ybih_player] ybih.turn 0
