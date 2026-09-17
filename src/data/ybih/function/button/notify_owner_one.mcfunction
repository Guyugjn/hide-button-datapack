# ybih:button/notify_owner_one —— 只通知 id 匹配物主的那位玩家

execute if score @s ybih.id = #press_owner ybih.config run tellraw @s {{TXT_S}}你的按钮被找到了{{TXT_M}}red{{TXT_E}}
