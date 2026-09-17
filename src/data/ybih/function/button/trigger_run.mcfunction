# ybih:button/trigger_run —— 聊天栏点击入口：只在藏匿阶段受理，读完值立刻清零

execute unless score #state ybih.config matches 2 run scoreboard players set @s ybih.trigger 0
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 1 run function ybih:button/confirm_do
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 2 run function ybih:button/redo_do
scoreboard players set @s ybih.trigger 0
