# ybih:game/start_begin —— 开局准备
# 轮流模式一轮只有一人藏，所以一局总轮数 = 周期数 × 参与人数

function ybih:util/cleanup_all
# 本局编号：跨局遗留在世界里的旧按钮标记靠它区分，不会被当成本局按钮
scoreboard players add #era ybih.config 1
scoreboard players set #next_id ybih.config 1
scoreboard players set #round ybih.config 1
scoreboard players set #cycle ybih.config 1
scoreboard players set @a ybih.score 0
# 上一局的榜单里可能还留着已经退出的人，开新局先整榜清空
scoreboard players reset * ybih.board
scoreboard players set @a ybih.placed 0
scoreboard players set @a ybih.turn 0
scoreboard players set @a ybih.found 0
scoreboard players set @a ybih.finds 0
scoreboard players set @a ybih.t_first 999999
scoreboard players set @a ybih.trigger 0
tag @a remove ybih_player
tag @a remove ybih_current
tag @a remove ybih_top
tag @a remove ybih_ranked

execute as @a[gamemode=!spectator] run function ybih:player/join_game
execute as @a[tag=!ybih_player] run scoreboard players set @s ybih.id 0

# 对局期间不吃饥饿也不受伤，名单以这一 tick 定下来的参与者为准
execute as @a[tag=ybih_player] run function ybih:player/apply_buff

scoreboard players set #player_count ybih.config 0
execute as @a[tag=ybih_player] run scoreboard players add #player_count ybih.config 1
scoreboard players operation #rounds_total ybih.config = #rounds ybih.config
execute if score #mode ybih.config matches 2 run scoreboard players operation #rounds_total ybih.config *= #player_count ybih.config

scoreboard players set #tick ybih.config 0
scoreboard players set #gained ybih.config 0
scoreboard players set #ranked ybih.config 0
scoreboard players set #found_seq ybih.config 0
scoreboard players set #seekers_left ybih.config 0
scoreboard players set #best_score ybih.config -2147483648
scoreboard players set #best_finds ybih.config -1
scoreboard players set #best_tfirst ybih.config 999999
scoreboard players set #best_id ybih.config 0

execute if entity @e[tag=ybih_center] as @a[tag=ybih_player] run tp @s @e[tag=ybih_center,limit=1]

# 等待室与边界都以集合点为准，每局开局重建；边界到这一刻才真正落到世界上
function ybih:util/build_wait_room
execute if score #border_on ybih.config matches 1 run function ybih:util/border_apply

scoreboard players set #state ybih.config 1
scoreboard players operation #timer ybih.config = #prep_time ybih.config
scoreboard players set #actionbar_timer ybih.config 20
function ybih:game/bar_show

title @a title [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮{{TXT_E}}]
execute if score #mode ybih.config matches 2 run title @a subtitle {{TXT_S}}轮流 · 一人藏，其余人找{{TXT_E}}
execute unless score #mode ybih.config matches 2 run title @a subtitle {{TXT_S}}经典 · 每人藏一个，全体一起找{{TXT_E}}
tellraw @a {{TXT_S}}轮到你时会拿到全套按钮，只能藏一个{{TXT_E}}
