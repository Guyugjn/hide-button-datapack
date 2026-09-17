# ybih:button/redo_do —— 聊天栏点了【取消重放】：退回材质并收回按钮，可以重新找位置

execute unless entity @s[tag=ybih_current] run tellraw @s {{TXT_S}}只有正在藏匿的玩家能重放{{TXT_M}}red{{TXT_E}}
execute if entity @s[tag=ybih_current] unless entity @e[tag=ybih_pending] run tellraw @s {{TXT_S}}现在没有待确认的按钮{{TXT_M}}red{{TXT_E}}
execute if entity @s[tag=ybih_current] if entity @e[tag=ybih_pending] run function ybih:button/refund_pending
execute if entity @s[tag=ybih_current] if entity @e[tag=ybih_pending] run tellraw @s {{TXT_S}}已收回刚放下的按钮，请重新找个位置放下{{TXT_M}}green{{TXT_E}}
execute if entity @s[tag=ybih_current] if entity @e[tag=ybih_pending] run scoreboard players enable @s ybih.trigger
execute if entity @s[tag=ybih_current] as @e[tag=ybih_pending] run function ybih:button/retract_pending
