# ybih:game/enter_turn —— 进入藏匿阶段
# 经典模式每轮所有参与者轮流藏；轮流模式每轮只有一人藏，轮到谁是开局前就定好的

scoreboard players set #state ybih.config 2
function ybih:turn/reset
function ybih:game/turn_next
