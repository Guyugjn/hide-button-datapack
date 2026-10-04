# ybih:button/try_register —— 从眼位出发做射线，寻找刚放下的按钮
# 显式把位置与朝向切到玩家自身，不依赖调用方隐式提供的上下文
# 上一次放下但还没确认的按钮先退回材质再收回，等于换个位置

execute if entity @e[tag=ybih_pending] run function ybih:button/refund_pending
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending
scoreboard players operation #ray_owner ybih.config = @s ybih.id
scoreboard players set #ray_step ybih.config 0
tag @s remove ybih_ray_found
execute at @s anchored eyes run function ybih:button/ray_loop
# 射线走完仍没认出按钮：方块的坐标从来没进过任何一条命令，事后无从查起，
# 唯一能确定的就是「这条射线没找到」。所以只提示，不按邻格去猜位置撤回 —— 猜错会删掉地图自带的按钮
execute unless entity @s[tag=ybih_ray_found] run tellraw @s {{TXT_S}}没能在你视线里认出刚放下的按钮，请靠近一点再放一个{{TXT_M}}red{{TXT_E}}
execute unless entity @s[tag=ybih_ray_found] run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8
