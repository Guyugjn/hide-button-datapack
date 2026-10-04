# ybih:game/showcase_bar_owner —— 把当前按钮物主的名字写进 Boss 栏标题
# 执行者是那位物主玩家
#
# 单独一个函数而不并进 showcase_bar：showcase_bar 也被 showcase_tick 每秒调用，
# 那时没有标记上下文、也取不到物主，只有切换的那一帧才知道物主是谁。
# 所以名字在切换时写一次，之后每秒的刷新沿用同样的文案

execute if score #show_found ybih.config matches 1 run bossbar set ybih:timer name [{{TXT_S}}分被拿完的按钮 · {{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 藏的 · {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
execute if score #show_found ybih.config matches 0 run bossbar set ybih:timer name [{{TXT_S}}还有分的按钮 · {{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 藏的 · {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
