# ybih:config/mode_2 —— 切换到轮流模式：一人藏，其余人抢着找

execute unless score #state ybih.config matches 0 run tellraw @s {{TXT_S}}对局进行中，不能切换模式{{TXT_M}}red{{TXT_E}}
execute if score #state ybih.config matches 0 run scoreboard players set #mode ybih.config 2
execute if score #state ybih.config matches 0 run function ybih:config/notify
