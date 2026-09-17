# ybih:game/showcase_restore —— 把被按掉的按钮临时摆回原位（执行者是该按钮的标记）
# 复用保护机制那套「按材质与朝向还原」，但多一道水的检查：
# 保护机制是每 5 秒复查一次，冲掉了还会再摆回去；围观只摆这一次，被冲掉就没了

scoreboard players set #wet ybih.config 0
function ybih:button/fluid_check
execute if score #wet ybih.config matches 0 run function ybih:button/protect_restore
