# ybih:button/press_broadcast_owner —— 带物主名字的那一版播报（执行者是物主本人）
# 由 button/press_broadcast 只在「物主在线」时调进来；按下者靠临时标记反选
#
tellraw @a [{{SEL_S}}@e[tag=ybih_presser,limit=1]{{SEL_E}},{{TXT_S}} 从 {{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 藏的按钮上取走 {{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
