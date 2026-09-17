# ybih:button/register_ok —— 材质识别成功：记录物主与本局编号，登记为待确认按钮
# 由 register_here 在确认材质属于本包清单之后调用，执行者是射线发起玩家

tag @s add ybih_ray_found
# 按钮编号：按下判定靠它把「玩家交互的按钮」与「被按下的按钮」对上。
# 跨局不重置，和 #era 同待遇 —— 编号只求唯一，不要求从 1 开始，
# 重置反而会让往局残留的标记与本届新按钮撞号
scoreboard players add #bid ybih.config 1
execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run scoreboard players operation @s ybih.bid = #bid ybih.config
# 同一格重新藏按钮时上一轮留下的旧记录就作废了，否则围观时这一格会被展示两次。
# 用刚召唤出来的标记来定位：射线点不一定落在目标格内，直接 align 会偏
execute at @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run kill @e[tag=ybih_ghost,distance=..0.8]
execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run scoreboard players operation @s ybih.owner_id = #ray_owner ybih.config
execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run scoreboard players operation @s ybih.era = #era ybih.config
# 藏匿先后顺序：轮末围观按这个编号从小到大展示，先藏的先看。
# 加在同格去重之后，被作废的旧记录不会占掉序号
scoreboard players add #seq ybih.config 1
execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run scoreboard players operation @s ybih.seq = #seq ybih.config
execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] run tag @s add ybih_pending

# 泡在水里或会被水漫进来的放置直接作废：水会把按钮冲掉，留着它只会一直复制按钮物品
scoreboard players set #wet ybih.config 0
execute as @e[tag=ybih_pending,distance=..2,limit=1,sort=nearest] at @s run function ybih:button/fluid_check
execute if score #wet ybih.config matches 1 run function ybih:button/fluid_reject

# 边界开着时，贴到最外一圈的放置也作废：退回材质并清掉方块，不让它留在边界那一格。
# 水那道已经判过就整段跳过：它退回时会连标记一起删掉，坐标随之取不到，
# 再拿清零后的 0 去减集合点坐标会得到一个巨大的差值，被误判成越界、白弹一条提示
scoreboard players set #out_border ybih.config 0
execute if score #wet ybih.config matches 0 if score #border_on ybih.config matches 1 if entity @e[tag=ybih_center] run function ybih:button/border_edge_check
execute if score #out_border ybih.config matches 1 run function ybih:button/border_reject

tag @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] remove ybih_new
execute if score #out_border ybih.config matches 0 if score #wet ybih.config matches 0 if score #confirm ybih.config matches 2 run function ybih:button/confirm_place
execute if score #out_border ybih.config matches 0 if score #wet ybih.config matches 0 unless score #confirm ybih.config matches 2 run function ybih:button/offer_confirm
