# ybih:game/showcase_begin —— 轮末带全体看一遍本局每一个藏过的按钮
# 展示对象是本局每一个藏过按钮的人，两类标记都算：
#   ybih_button —— 分还没被拿完、仍在场上的
#   ybih_ghost  —— 分已被拿完的，方块收走了但记录还在，围观时临时摆回去
# 关掉围观开关时 #show_total 保持 0，直接走收尾，不做任何传送

scoreboard players set #show_total ybih.config 0
execute if score #showcase_on ybih.config matches 1 as @e[tag=ybih_button] if score @s ybih.era = #era ybih.config run scoreboard players add #show_total ybih.config 1
execute if score #showcase_on ybih.config matches 1 as @e[tag=ybih_ghost] if score @s ybih.era = #era ybih.config run scoreboard players add #show_total ybih.config 1
execute if score #show_total ybih.config matches 0 run function ybih:game/end_round_finish
execute if score #show_total ybih.config matches 1.. run function ybih:game/showcase_start
