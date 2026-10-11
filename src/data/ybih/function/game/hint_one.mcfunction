# ybih:game/hint_one —— 检测最近的别人的按钮落在哪一档，并在残局补报方位
# 半径由 #hint_range 决定，逐档扫描与档位文案都在生成的 hint_scan 里；
# 那一步结束时 #hint_band 已经写好：档位半径，或 0（范围内没有别人的按钮）
#
# 档位文案由 hint_scan 自己发（它才知道档位字面量），所以这里不再写 tellraw
#
# 残局补报方位：只在「已经进了残局」且「确实探到了别人的按钮」时做。
# 探不到时不必报方位 —— 没有任何目标可指，报出来只会让人扑空。
# 方位函数要读玩家坐标，所以必须 as 到玩家本人；这里已经在玩家身上（hint_all 逐个调进来）

scoreboard players set #hint_band ybih.config 0
scoreboard players operation #hint_self ybih.config = @s ybih.id
function ybih:game/hint_scan

execute if score #timer ybih.config <= #late_from ybih.config if score #hint_band ybih.config matches 1.. run function ybih:game/hint_dir
