# ybih:game/hint_one —— 检测附近是否存在别人的按钮
# 半径由 #hint_range 决定，实际扫描交给生成的 hint_scan 逐档分派；
# 文案里的数字用 score 组件直接读，改设置之后不用动这里

scoreboard players set #hint_hit ybih.config 0
scoreboard players operation #hint_self ybih.config = @s ybih.id
function ybih:game/hint_scan
execute if score #hint_hit ybih.config matches 1 run title @s actionbar [{{SCORE_HINTRANGE}},{{TXT_S}} 格内有别人的按钮{{TXT_M}}red{{TXT_E}}]
execute if score #hint_hit ybih.config matches 0 run title @s actionbar [{{SCORE_HINTRANGE}},{{TXT_S}} 格内没有按钮{{TXT_M}}gray{{TXT_E}}]
