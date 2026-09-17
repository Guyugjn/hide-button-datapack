# ybih:config/confirm_on —— 开启放错确认：放下按钮后要在聊天栏点【确认】才生效

execute unless score #state ybih.config matches 0 run tellraw @s {{TXT_S}}对局进行中，不能改这项设置{{TXT_M}}red{{TXT_E}}
execute if score #state ybih.config matches 0 run scoreboard players set #confirm ybih.config 1
execute if score #state ybih.config matches 0 run function ybih:config/notify
