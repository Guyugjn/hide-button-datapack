# ybih:util/remove_wait_room —— 拆掉高空等待室
# 先靠集合点把还关在里面的人送出来；集合点不在就整体不拆，免得有人从高空摔下去
# 拆除范围从基准层一路铺到 ~8，把老存档里按旧规格建偏了的那间也一并清掉

execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] as @a[distance=..15] run tp @s @e[tag=ybih_center,limit=1]
execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] run fill ~-5 ~ ~-5 ~5 ~8 ~5 air
execute if entity @e[tag=ybih_center] run kill @e[tag=ybih_room]
