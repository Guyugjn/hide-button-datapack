# ybih:player/join_game —— 玩家入队：分配 id、记录原游戏模式

tag @s add ybih_player
scoreboard players operation @s ybih.id = #next_id ybih.config
scoreboard players add #next_id ybih.config 1
scoreboard players set @s ybih.score 0
scoreboard players set @s ybih.placed 0
scoreboard players set @s ybih.turn 0
scoreboard players set @s ybih.found 0
scoreboard players set @s ybih.finds 0
scoreboard players set @s ybih.t_first 999999
scoreboard players set @s ybih.trigger 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0

# 先撤掉可能残留的记录：局中掉线的人赶不上清场，标签会跟着存档留到下一局，
# 新旧两个同时命中时，恢复模式那几条命令里靠后的会盖掉靠前的
tag @s remove ybih_gm_survival
tag @s remove ybih_gm_creative
tag @s remove ybih_gm_adventure
execute if entity @s[gamemode=survival] run tag @s add ybih_gm_survival
execute if entity @s[gamemode=creative] run tag @s add ybih_gm_creative
execute if entity @s[gamemode=adventure] run tag @s add ybih_gm_adventure

gamemode adventure @s
