# ybih:config/confirm_off —— 关闭放错确认：放下按钮立刻生效

execute unless score #state ybih.config matches 0 run tellraw @s {{TXT_S}}对局进行中，不能改这项设置{{TXT_M}}red{{TXT_E}}
execute if score #state ybih.config matches 0 run scoreboard players set #confirm ybih.config 2
execute if score #state ybih.config matches 0 run function ybih:config/notify
