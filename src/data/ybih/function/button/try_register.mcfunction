# ybih:button/try_register —— 从眼位出发做射线，寻找刚放下的按钮
# 显式把位置与朝向切到玩家自身，不依赖调用方隐式提供的上下文
# 上一次放下但还没确认的按钮先退回材质再收回，等于换个位置

execute if entity @e[tag=ybih_pending] run function ybih:button/refund_pending
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending
scoreboard players operation #ray_owner ybih.config = @s ybih.id
scoreboard players set #ray_step ybih.config 0
tag @s remove ybih_ray_found
execute at @s anchored eyes run function ybih:button/ray_loop
