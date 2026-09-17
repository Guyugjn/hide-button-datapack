# ybih:config/showcase_off —— 关闭轮末围观：轮末直接结算，不做传送展示

scoreboard players set #showcase_on ybih.config 0
tellraw @s {{TXT_S}}轮末围观已关闭{{TXT_M}}green{{TXT_E}}
function ybih:config/notify
