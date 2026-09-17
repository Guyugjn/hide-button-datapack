# ybih:game/enter_searching_rotate —— 轮流模式：搜寻者回集合点，藏匿者转旁观观战

scoreboard players set #seekers_left ybih.config 0
scoreboard players set #found_seq ybih.config 0
execute as @a[tag=ybih_player,tag=!ybih_current] run scoreboard players add #seekers_left ybih.config 1

execute if entity @e[tag=ybih_center] as @a[tag=ybih_player,tag=!ybih_current] run tp @s @e[tag=ybih_center,limit=1]

gamemode spectator @a[tag=ybih_current]
effect give @a[tag=ybih_current] minecraft:night_vision 999999 0 true
execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]

title @a[tag=ybih_player,tag=!ybih_current] title {{TXT_S}}开始寻找{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_player,tag=!ybih_current] subtitle {{TXT_S}}第一个找到的人分最高{{TXT_E}}
title @a[tag=ybih_current] title {{TXT_S}}你的按钮藏好了{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_current] subtitle {{TXT_S}}现在可以旁观观战{{TXT_E}}
tellraw @a[tag=ybih_player,tag=!ybih_current] [{{TXT_S}}本轮搜寻者 {{TXT_E}},{{SCORE_SEEKERS}},{{TXT_S}} 人{{TXT_E}}]
