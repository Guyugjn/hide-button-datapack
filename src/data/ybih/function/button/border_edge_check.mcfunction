# ybih:button/border_edge_check —— 判定刚放下的按钮是不是贴到了边界最外一圈
# 口径：按钮到集合点的水平距离（切比雪夫，取 x/z 里大的那个）必须 ≤ 半径 − 1
# 坐标乘 100 再存进记分板，保留两位小数，免得取整误差正好吃掉那一格余量

# 先清零再去坐标，免得某一次取不到时残留上一轮的值。
# 调用方保证了执行到这里标记还在（水那道校验会先删标记并跳过本段），
# 否则两个坐标停在 0、和集合点一减就成了巨大的差值，会被误判成越界
scoreboard players set #bx ybih.config 0
scoreboard players set #bz ybih.config 0
scoreboard players set #cx ybih.config 0
scoreboard players set #cz ybih.config 0

execute store result score #bx ybih.config run data get entity @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] Pos[0] 100
execute store result score #bz ybih.config run data get entity @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] Pos[2] 100
execute store result score #cx ybih.config run data get entity @e[tag=ybih_center,limit=1] Pos[0] 100
execute store result score #cz ybih.config run data get entity @e[tag=ybih_center,limit=1] Pos[2] 100

scoreboard players operation #dx ybih.config = #bx ybih.config
scoreboard players operation #dx ybih.config -= #cx ybih.config
scoreboard players operation #dz ybih.config = #bz ybih.config
scoreboard players operation #dz ybih.config -= #cz ybih.config
execute if score #dx ybih.config matches ..-1 run scoreboard players operation #dx ybih.config *= #neg ybih.config
execute if score #dz ybih.config matches ..-1 run scoreboard players operation #dz ybih.config *= #neg ybih.config

# 限值取世界边界的真实直径，而不是书里选的档位值 —— 用户可能手动敲过 /worldborder set，
# 那种情况下档位与实际尺寸会脱节，按档位判定会在离墙还很远的地方就误拒
execute in minecraft:overworld store result score #bw_now ybih.config run worldborder get
scoreboard players operation #lim ybih.config = #bw_now ybih.config
scoreboard players operation #lim ybih.config /= #c2 ybih.config
scoreboard players remove #lim ybih.config 1
scoreboard players operation #lim ybih.config *= #c100 ybih.config

execute if score #dx ybih.config > #lim ybih.config run scoreboard players set #out_border ybih.config 1
execute if score #dz ybih.config > #lim ybih.config run scoreboard players set #out_border ybih.config 1
