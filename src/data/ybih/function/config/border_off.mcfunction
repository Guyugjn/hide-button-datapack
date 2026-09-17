# ybih:config/border_off —— 关闭活动边界，并立刻把世界边界恢复成初始状态

scoreboard players set #border_on ybih.config 0
function ybih:util/border_reset
tellraw @s {{TXT_S}}边界已关闭并恢复初始{{TXT_M}}green{{TXT_E}}
function ybih:config/notify
