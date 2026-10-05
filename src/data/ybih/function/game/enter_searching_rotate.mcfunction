# ybih:game/enter_searching_rotate —— 轮流模式：搜寻者回集合点，藏匿者转旁观观战

scoreboard players set #seekers_total ybih.config 0
execute as @a[tag=ybih_player,tag=!ybih_current] run scoreboard players add #seekers_total ybih.config 1

execute if entity @e[tag=ybih_center] as @a[tag=ybih_player,tag=!ybih_current] run tp @s @e[tag=ybih_center,limit=1]

gamemode spectator @a[tag=ybih_current]
# 藏匿者在这段搜寻期是旁观，给他一份观战夜视。
# 时长取 60 秒而不是 999999：断线的人会把剩余时长连同凭据一起存进存档，
# 而效果时长在离线期间不递减 —— 一次性长时长会陪着他跨局、跨 reload、跨重连一直挂着。
# 60 秒由 player/buff_guard 在「还是搜寻阶段、且是轮流模式」时每秒顶上，够亮；
# 判据一旦不成立，凭据与效果一秒内一起收掉（见 game/current_clear）
effect give @a[tag=ybih_current] minecraft:night_vision 60 0 true
execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]

title @a[tag=ybih_player,tag=!ybih_current] title {{TXT_S}}开始寻找{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_player,tag=!ybih_current] subtitle {{TXT_S}}按钮有分，谁先按谁分高{{TXT_E}}
title @a[tag=ybih_current] title {{TXT_S}}你的按钮藏好了{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_current] subtitle {{TXT_S}}现在可以旁观观战{{TXT_E}}
tellraw @a[tag=ybih_player,tag=!ybih_current] [{{TXT_S}}本轮搜寻者 {{TXT_E}},{{SCORE_SEEKERS}},{{TXT_S}} 人{{TXT_E}}]
