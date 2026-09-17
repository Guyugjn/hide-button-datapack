# ybih:game/next_round —— 进入下一轮（分数保留，按钮重发）

scoreboard players add #round ybih.config 1

execute as @a[gamemode=!spectator,tag=!ybih_player] run function ybih:player/join_game

# 轮流模式：回合总数按「此刻的参与者数」重算，中途进服的人不会被漏掉
scoreboard players set #player_count ybih.config 0
execute as @a[tag=ybih_player] run scoreboard players add #player_count ybih.config 1
execute if score #mode ybih.config matches 2 run scoreboard players operation #rounds_total ybih.config = #rounds ybih.config
execute if score #mode ybih.config matches 2 run scoreboard players operation #rounds_total ybih.config *= #player_count ybih.config

scoreboard players set @a[tag=ybih_player] ybih.placed 0
scoreboard players set @a[tag=ybih_player] ybih.found 0
# 新的一轮，藏匿编号从头开始
scoreboard players set #seq ybih.config 0
execute if score #mode ybih.config matches 1 run scoreboard players set @a[tag=ybih_player] ybih.turn 0
tag @a remove ybih_current
tag @a remove ybih_top
tag @a remove ybih_ranked

execute if entity @e[tag=ybih_center] as @a[tag=ybih_player] run tp @s @e[tag=ybih_center,limit=1]

scoreboard players set #state ybih.config 1
scoreboard players operation #timer ybih.config = #prep_time ybih.config
scoreboard players set #actionbar_timer ybih.config 20

title @a title [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮{{TXT_E}}]
title @a subtitle {{TXT_S}}准备开始{{TXT_E}}
tellraw @a {{TXT_S}}分数累计保留，轮到你时会拿到按钮{{TXT_M}}gray{{TXT_E}}

# 全员找到会直接从按下检测走到这里，不经过每秒循环
function ybih:game/bar_update
