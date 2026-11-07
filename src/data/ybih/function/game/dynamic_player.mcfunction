# ybih:game/dynamic_player —— 统计当前玩家仍可领取的按钮
# 执行者是在线参与者；先算一次位图掩码，再遍历本局按钮。

scoreboard players operation #dyn_id ybih.config = @s ybih.id
function ybih:button/hit_bit
execute if score #hit_bit ybih.config matches 1.. as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config run function ybih:game/dynamic_button
