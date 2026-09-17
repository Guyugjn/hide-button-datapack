# ybih:button/register_here —— 在按钮所在方块的中心召唤标记并记录物主、材质、朝向
# 标记必须精确落在方块中心，否则后续 setblock 与方块状态检测会取整到相邻方块
# 材质不在本包清单内的候选直接撤掉，让射线继续往里找玩家真正放下的那个

execute align xyz run summon armor_stand ~0.5 ~ ~0.5 {Tags:["ybih_button","ybih_new"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}
function ybih:button/tag_material
function ybih:button/tag_face
execute if entity @e[tag=ybih_new,tag=ybih_unknown,distance=..2] run function ybih:button/drop_unknown
execute unless entity @e[tag=ybih_new,tag=ybih_unknown,distance=..2] run function ybih:button/register_ok
