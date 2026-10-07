# ybih:util/remove_wait_room —— 拆掉高空等待室
# 先靠集合点把还关在里面的人送出来；集合点不在就整体不拆，免得有人从高空摔下去
# 拆除范围比实际建造的外壳各向外多留一格：相对坐标取了整，标记又落在小数的位置上，
# fill 的边界会随集合点的小数部分左右挪一格，不多留就会在天上留下一条残壳
# 纵向最高到 ~8：既覆盖现在的地板层，也把老存档里按旧规格建偏了的那间一并清掉
#
# 必须分两条、且地基那条排最后。fill 内部是自下而上执行的，一条 ~-1..~8 会先抽掉
# 基准层下面那层地基，地毯随之失去支撑、当场崩成掉落物掉一地（实测 69 个物品），
# 再从 245 的高空一路摔到地面。拆的顺序反过来就不会：地基还在时地毯是被 fill 直接
# 替换掉的，replace 不产生掉落，等轮到收地基时上面已经没有需要支撑的方块了

execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] as @a[distance=..16] run tp @s @e[tag=ybih_center,limit=1]
# 先拆基准层及以上：这一步把地毯与房子一起收掉，此时地基尚在，不掉落
execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] run fill ~-7 ~ ~-7 ~7 ~8 ~7 air
# 最后收地基：收晚了会留一块浮空木板，收早了地毯会掉
execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] run fill ~-7 ~-1 ~-7 ~7 ~-1 ~7 air
execute if entity @e[tag=ybih_center] run kill @e[tag=ybih_room]
