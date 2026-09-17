# ybih:player/spectate —— 转为旁观：夜视并传送到中心点

gamemode spectator @s
effect give @s minecraft:night_vision 999999 0 true
execute if entity @e[tag=ybih_center] run tp @s @e[tag=ybih_center,limit=1]
tellraw @s {{TXT_S}}你以旁观身份观看本局{{TXT_M}}gray{{TXT_E}}
