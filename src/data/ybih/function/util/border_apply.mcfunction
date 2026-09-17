# ybih:util/border_apply —— 把边界对到集合点，并按书里选的半径设好尺寸
# 书里的半径是玩家口径，命令收的是正方形边长，所以半径 50 对应 set 100
# 尺寸写死作用在主世界：这个命令只影响执行时所在的维度，中心那一句同样钉死主世界
# 半径那一项选的是「跟随手动」时 #border_r 为 0，九个档位都不命中，尺寸保持不动

execute in minecraft:overworld if entity @e[tag=ybih_center] at @e[tag=ybih_center,limit=1] run worldborder center ~ ~
execute in minecraft:overworld if score #border_r ybih.config matches 20 run worldborder set 40
execute in minecraft:overworld if score #border_r ybih.config matches 30 run worldborder set 60
execute in minecraft:overworld if score #border_r ybih.config matches 40 run worldborder set 80
execute in minecraft:overworld if score #border_r ybih.config matches 50 run worldborder set 100
execute in minecraft:overworld if score #border_r ybih.config matches 60 run worldborder set 120
execute in minecraft:overworld if score #border_r ybih.config matches 70 run worldborder set 140
execute in minecraft:overworld if score #border_r ybih.config matches 80 run worldborder set 160
execute in minecraft:overworld if score #border_r ybih.config matches 90 run worldborder set 180
execute in minecraft:overworld if score #border_r ybih.config matches 100 run worldborder set 200
