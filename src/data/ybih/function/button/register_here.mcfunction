# ybih:button/register_here —— 在按钮所在方块的中心召唤标记并记录物主、材质、朝向
# 标记必须精确落在方块中心，否则后续 setblock 与方块状态检测会取整到相邻方块
# 材质不在本包清单内的候选直接撤掉，让射线继续往里找玩家真正放下的那个

execute align xyz run summon armor_stand ~0.5 ~ ~0.5 {Tags:["ybih_button","ybih_new"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}
function ybih:button/tag_material
function ybih:button/tag_face
# 这两行的**先后不能调换**：drop_unknown 会当场 kill 掉未知材质的候选标记，
# 而 kill 在同一函数里立刻生效。原先先判「有未知」再判「无未知」，
# 第二行的条件在第一行删完之后必然成立，于是未知材质也会走一遍 register_ok：
# 记号既没登记上、又占掉一个编号，射线还被标成命中，玩家什么都收不到。
# 现在先判无未知（登记），再判有未知（撤掉让射线继续往里找）
execute unless entity @e[tag=ybih_new,tag=ybih_unknown,distance=..2] run function ybih:button/register_ok
execute if entity @e[tag=ybih_new,tag=ybih_unknown,distance=..2] run function ybih:button/drop_unknown
