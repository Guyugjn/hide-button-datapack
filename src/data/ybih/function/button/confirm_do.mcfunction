# ybih:button/confirm_do —— 聊天栏点了【确认】

execute unless entity @s[tag=ybih_current] run tellraw @s {{TXT_S}}只有正在藏匿的玩家能确认{{TXT_M}}red{{TXT_E}}
execute if entity @s[tag=ybih_current] unless entity @e[tag=ybih_pending] run tellraw @s {{TXT_S}}现在没有待确认的按钮{{TXT_M}}red{{TXT_E}}
execute if entity @s[tag=ybih_current] if entity @e[tag=ybih_pending] unless score @s ybih.placed matches 1 run function ybih:button/confirm_place
