# ybih:config/set_center_here —— 把集合点设在执行者站立的位置

# 换位置之前先把旧集合点占着的区块放开。中心标记没打 ybih_pinned（它不是本局申请的那类对象），
# 释放点选不中它，只能按它的位置来放；而且必须排在 kill 之前 —— 标记一没，位置也就没了
# 首次设置时 @e[tag=ybih_center] 是空的，这一条自然什么都不做
execute at @e[tag=ybih_center] run forceload remove ~ ~
kill @e[tag=ybih_center]
execute at @s run summon armor_stand ~ ~ ~ {Tags:["ybih_center"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}
# 集合点靠它的区块被强加载才一直有效：等待室、集结传送、边界中心都按它算。
# 它没有 ybih_pinned 凭据、也不该被本局的清理路径放开，所以换位置时只能靠上面那条自己收尾
execute at @s run forceload add ~ ~
playsound minecraft:block.beacon.activate player @s ~ ~ ~ 1 1.4
tellraw @s {{TXT_S}}[你的按钮我来藏] 集合点已设置在当前位置{{TXT_M}}green{{TXT_E}}
execute if score #border_on ybih.config matches 1 run tellraw @s {{TXT_S}}活动边界开着：中心会在开局时跟到这个新位置，尺寸不合适就回书里重新选个半径{{TXT_M}}yellow{{TXT_E}}
