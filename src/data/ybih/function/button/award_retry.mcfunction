# ybih:button/award_retry —— 结算没落地：本次不计分，撤掉闸门让玩家原地再按一次
# 位图没置上、分数没动，这次按下等于没发生过，所以可以安全重试
#
# 两样都要撤，缺一不可：
#   ybih_pressed 不撤 → 这个 powered 窗口再也判不了，玩家按下去没反应
#   ybih_active 不撤  → press_scan 见没有 ybih_pressed 就走 press_down，
#                       而那一侧只查「有没有亮起」，方块早已弹起，于是 press_up
#                       永远不会跑、release 也就不会被调用，这个标记会一直挂着
#                       ybih_active 直到下一次任何按钮被按下（press_begin 会先清空）
#                       眼下那段窗口里 award_* 都不会被调用，够不成实际错误；
#                       但「未按下就一定没有 ybih_active」这条不变量一旦破掉，
#                       以后任何读 ybih_active 的新代码都会踩到它。这里一并撤掉，
#                       让不变量无条件成立，不必依赖时序论证

tag @e[tag=ybih_active] remove ybih_pressed
tag @e[tag=ybih_active] remove ybih_active
tellraw @s {{TXT_S}}这次点击没有生效，请再按一次{{TXT_M}}yellow{{TXT_E}}
