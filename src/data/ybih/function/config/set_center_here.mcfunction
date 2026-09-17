# ybih:config/set_center_here —— 把集合点设在执行者站立的位置

kill @e[tag=ybih_center]
execute at @s run summon armor_stand ~ ~ ~ {Tags:["ybih_center"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}
execute at @s run forceload add ~ ~
playsound minecraft:block.beacon.activate player @s ~ ~ ~ 1 1.4
tellraw @s {{TXT_S}}[你的按钮我来藏] 集合点已设置在当前位置{{TXT_M}}green{{TXT_E}}
execute if score #border_on ybih.config matches 1 run tellraw @s {{TXT_S}}活动边界开着：中心会在开局时跟到这个新位置，尺寸不合适就回书里重新选个半径{{TXT_M}}yellow{{TXT_E}}
