# ybih:button/notify_first_find —— 按钮第一次被找到时通知物主
# 由 button/award_score 在 #first_find = 1 时调进来
#
# 通知分两档，与保底分的两档梯度对齐：
#   更早被找到       → 保底分全没（那份价值已在按下的一刻结清）
#   到最后三分之一才被找到 → 保底分减半，且这份半档已由 button/bonus_half 当场发给他
#
# 半档为 0（人数不足 4 人，floor(N/4) 落到 0）时回落成「全没」那一句：
# 一分都没拿到还说「减半」会让人以为漏发了
#
# 物主此刻不在线就静默跳过（@a 选不中离线玩家）—— 他本来也拿不到那份保底分，
# 不必为一件已经不存在的事留通知

execute if score #timer ybih.config > #late_from ybih.config as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run tellraw @s {{TXT_S}}你的按钮被找到了，藏到底的保底分没了{{TXT_M}}red{{TXT_E}}
execute if score #timer ybih.config <= #late_from ybih.config if score #bonus_half ybih.config matches ..0 as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run tellraw @s {{TXT_S}}你的按钮被找到了，藏到底的保底分没了{{TXT_M}}red{{TXT_E}}
