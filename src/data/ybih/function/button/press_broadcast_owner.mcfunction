# ybih:button/press_broadcast_owner —— 带物主名字的那一版播报（执行者是物主本人）
# 由 button/press_broadcast 只在「物主在线」时调进来；按下者靠临时标记反选
#
# 分两条：还剩分与分被拿完，文案不同。判据用 #btn_remain（这次取走后剩下的份数），
# 它在 award_score 里算好，这里只读

execute if score #btn_remain ybih.config matches 1.. run tellraw @a [{{SEL_S}}@e[tag=ybih_presser,limit=1]{{SEL_E}},{{TXT_S}} 从 {{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 藏的按钮上取走 {{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分 · 还剩 {{TXT_E}},{{SCORE_BTNREMAIN}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #btn_remain ybih.config matches ..0 run tellraw @a [{{SEL_S}}@e[tag=ybih_presser,limit=1]{{SEL_E}},{{TXT_S}} 从 {{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 藏的按钮上取走 {{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分 · 这个按钮的分拿完了，它被收走{{TXT_M}}gold{{TXT_E}}]
