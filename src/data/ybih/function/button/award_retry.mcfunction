# ybih:button/award_retry —— 结算没落地：本次不计分，撤掉闸门让玩家原地再按一次
# 位图没置上、分数没动，这次按下等于没发生过，所以可以安全重试

tag @e[tag=ybih_active] remove ybih_pressed
tellraw @s {{TXT_S}}这次点击没有生效，请再按一次{{TXT_M}}yellow{{TXT_E}}
