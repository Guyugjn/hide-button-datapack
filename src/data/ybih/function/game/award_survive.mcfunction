# ybih:game/award_survive —— 判断自己的按钮是否还在场上

scoreboard players set #survive_hit ybih.config 0
scoreboard players operation #survive_self ybih.config = @s ybih.id
execute as @e[tag=ybih_button] if score @s ybih.era = #era ybih.config run function ybih:game/award_survive_probe
execute if score #survive_hit ybih.config matches 1 run scoreboard players add @s ybih.score 1
execute if score #survive_hit ybih.config matches 1 run tellraw @s {{TXT_S}}你的按钮没被找到，+1 分{{TXT_M}}green{{TXT_E}}
