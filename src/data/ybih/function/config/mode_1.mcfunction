# ybih:config/mode_1 —— 切换到经典模式：每人藏一个，全体一起找

execute unless score #state ybih.config matches 0 run tellraw @s {{TXT_S}}对局进行中，不能切换模式{{TXT_M}}red{{TXT_E}}
execute if score #state ybih.config matches 0 run scoreboard players set #mode ybih.config 1
execute if score #state ybih.config matches 0 run function ybih:config/notify
