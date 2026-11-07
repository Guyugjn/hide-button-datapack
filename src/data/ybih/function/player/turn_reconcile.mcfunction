# ybih:player/turn_reconcile —— 更新当前局玩家的轮次凭据并清除过期回合状态
# 经典模式按轮；轮流模式按周期。同一周期中的各小轮不能重复发放藏匿机会。
scoreboard players set @s ybih.turn 0
scoreboard players set @s ybih.placed 0
execute if score #mode ybih.config matches 1 run scoreboard players operation @s ybih.t_epoch = #round ybih.config
execute if score #mode ybih.config matches 2 run scoreboard players operation @s ybih.t_epoch = #cycle ybih.config
