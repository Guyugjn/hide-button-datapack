# ybih:game/hint_dir_pick —— 标记当前玩家尚未取分的候选按钮
# 执行者是按钮标记；与距离扫描共用筛选条件。

function ybih:game/hint_eligible
execute if score #hint_ok ybih.config matches 1 run tag @s add ybih_near
