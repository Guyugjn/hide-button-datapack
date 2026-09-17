# ybih:turn/gather —— 藏匿者回到中心点，其余参与者送进高空等待室

execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]
# 先确认等待室地板真的砌好了再送人，避免万一没建成把人从高空放下去
execute at @e[tag=ybih_room,limit=1] if block ~ ~ ~ minecraft:quartz_block as @a[tag=ybih_player,tag=!ybih_current] run tp @s ~ ~1 ~
title @a[tag=ybih_current] title {{TXT_S}}轮到你了{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_current] subtitle {{TXT_S}}藏好你的按钮{{TXT_E}}
tellraw @a[tag=ybih_player,tag=!ybih_current] {{TXT_S}}有人在藏按钮，请稍候{{TXT_M}}gray{{TXT_E}}
