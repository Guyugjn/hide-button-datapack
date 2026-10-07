# ybih:button/trigger_run —— 聊天栏点击入口：读完值立刻清零
# 藏匿阶段（#state 2）受理两类点击：按钮的确认 1 / 取消重放 2，等待室猜拳 11 / 12 / 13

execute unless score #state ybih.config matches 2 run scoreboard players set @s ybih.trigger 0
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 1 run function ybih:button/confirm_do
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 2 run function ybih:button/redo_do
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 11 run function ybih:room/rps_rock
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 12 run function ybih:room/rps_scissors
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 13 run function ybih:room/rps_paper
scoreboard players set @s ybih.trigger 0
