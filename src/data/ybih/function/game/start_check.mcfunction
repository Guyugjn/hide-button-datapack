# ybih:game/start_check —— 检查集合点是否就绪；只有一个人时给提示但照常开局

scoreboard players set #need_tool ybih.config 0
scoreboard players set #player_count ybih.config 0
execute as @a[gamemode=!spectator] run scoreboard players add #player_count ybih.config 1
execute if score #player_count ybih.config matches ..1 run tellraw @s {{TXT_S}}目前只有 1 名参与者，搜寻阶段不会有人按按钮{{TXT_M}}yellow{{TXT_E}}

execute unless entity @e[tag=ybih_center] run scoreboard players set #need_tool ybih.config 1
execute if score #need_tool ybih.config matches 1 run function ybih:game/start_tools
execute if score #need_tool ybih.config matches 0 run function ybih:game/start_begin
