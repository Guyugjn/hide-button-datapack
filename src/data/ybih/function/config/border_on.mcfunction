# ybih:config/border_on —— 开启活动边界（只记设置，开局时才真正落到世界上）

scoreboard players set #border_on ybih.config 1
tellraw @s {{TXT_S}}边界已开启，开局时才会出现{{TXT_M}}green{{TXT_E}}
function ybih:config/notify
