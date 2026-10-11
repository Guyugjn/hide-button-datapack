# ybih:button/notify_first_find —— 按钮第一次被找到时通知物主：保底分没了
# 由 button/award_score 在 #first_find = 1 时调进来
#
# 物主此刻不在线就静默跳过（@a 选不中离线玩家）—— 他本来也拿不到那份保底分，
# 不必为一件已经不存在的事留通知

execute as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run tellraw @s {{TXT_S}}你的按钮被找到了，藏到底的保底分没了{{TXT_M}}red{{TXT_E}}
