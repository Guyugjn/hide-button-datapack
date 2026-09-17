# ybih:start —— 开始游戏

playsound minecraft:ui.button.click player @s ~ ~ ~ 1 1
execute unless score #state ybih.config matches 0 run tellraw @s {{TXT_S}}对局进行中，请先 /function ybih:stop{{TXT_M}}red{{TXT_E}}
execute if score #state ybih.config matches 0 run function ybih:game/start_check
