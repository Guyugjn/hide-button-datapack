# ybih:player/bonus_settle —— 向本局重连玩家补发离线保底
scoreboard players set #bp_due ybih.config 0
execute if score @s ybih.id matches 1 run scoreboard players operation #bp_due ybih.config = #bp01 ybih.config
execute if score @s ybih.id matches 2 run scoreboard players operation #bp_due ybih.config = #bp02 ybih.config
execute if score @s ybih.id matches 3 run scoreboard players operation #bp_due ybih.config = #bp03 ybih.config
execute if score @s ybih.id matches 4 run scoreboard players operation #bp_due ybih.config = #bp04 ybih.config
execute if score @s ybih.id matches 5 run scoreboard players operation #bp_due ybih.config = #bp05 ybih.config
execute if score @s ybih.id matches 6 run scoreboard players operation #bp_due ybih.config = #bp06 ybih.config
execute if score @s ybih.id matches 7 run scoreboard players operation #bp_due ybih.config = #bp07 ybih.config
execute if score @s ybih.id matches 8 run scoreboard players operation #bp_due ybih.config = #bp08 ybih.config
execute if score @s ybih.id matches 9 run scoreboard players operation #bp_due ybih.config = #bp09 ybih.config
execute if score @s ybih.id matches 10 run scoreboard players operation #bp_due ybih.config = #bp10 ybih.config
execute if score @s ybih.id matches 11 run scoreboard players operation #bp_due ybih.config = #bp11 ybih.config
execute if score @s ybih.id matches 12 run scoreboard players operation #bp_due ybih.config = #bp12 ybih.config
execute if score @s ybih.id matches 13 run scoreboard players operation #bp_due ybih.config = #bp13 ybih.config
execute if score @s ybih.id matches 14 run scoreboard players operation #bp_due ybih.config = #bp14 ybih.config
execute if score @s ybih.id matches 15 run scoreboard players operation #bp_due ybih.config = #bp15 ybih.config
execute if score @s ybih.id matches 16 run scoreboard players operation #bp_due ybih.config = #bp16 ybih.config
execute if score @s ybih.id matches 17 run scoreboard players operation #bp_due ybih.config = #bp17 ybih.config
execute if score @s ybih.id matches 18 run scoreboard players operation #bp_due ybih.config = #bp18 ybih.config
execute if score @s ybih.id matches 19 run scoreboard players operation #bp_due ybih.config = #bp19 ybih.config
execute if score @s ybih.id matches 20 run scoreboard players operation #bp_due ybih.config = #bp20 ybih.config
execute if score @s ybih.id matches 21 run scoreboard players operation #bp_due ybih.config = #bp21 ybih.config
execute if score @s ybih.id matches 22 run scoreboard players operation #bp_due ybih.config = #bp22 ybih.config
execute if score @s ybih.id matches 23 run scoreboard players operation #bp_due ybih.config = #bp23 ybih.config
execute if score @s ybih.id matches 24 run scoreboard players operation #bp_due ybih.config = #bp24 ybih.config
execute if score @s ybih.id matches 25 run scoreboard players operation #bp_due ybih.config = #bp25 ybih.config
execute if score @s ybih.id matches 26 run scoreboard players operation #bp_due ybih.config = #bp26 ybih.config
execute if score @s ybih.id matches 27 run scoreboard players operation #bp_due ybih.config = #bp27 ybih.config
execute if score @s ybih.id matches 28 run scoreboard players operation #bp_due ybih.config = #bp28 ybih.config
execute if score @s ybih.id matches 29 run scoreboard players operation #bp_due ybih.config = #bp29 ybih.config
execute if score @s ybih.id matches 30 run scoreboard players operation #bp_due ybih.config = #bp30 ybih.config
execute if score #bp_due ybih.config matches 1.. run scoreboard players operation @s ybih.score += #bp_due ybih.config
execute if score #bp_due ybih.config matches 1.. run tellraw @s {{TXT_S}}离线期间的保底分已补发{{TXT_M}}gold{{TXT_E}}
execute if score #bp_due ybih.config matches 1.. run scoreboard players operation #bp_sum ybih.config -= #bp_due ybih.config
execute if score @s ybih.id matches 1 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp01 ybih.config 0
execute if score @s ybih.id matches 2 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp02 ybih.config 0
execute if score @s ybih.id matches 3 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp03 ybih.config 0
execute if score @s ybih.id matches 4 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp04 ybih.config 0
execute if score @s ybih.id matches 5 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp05 ybih.config 0
execute if score @s ybih.id matches 6 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp06 ybih.config 0
execute if score @s ybih.id matches 7 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp07 ybih.config 0
execute if score @s ybih.id matches 8 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp08 ybih.config 0
execute if score @s ybih.id matches 9 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp09 ybih.config 0
execute if score @s ybih.id matches 10 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp10 ybih.config 0
execute if score @s ybih.id matches 11 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp11 ybih.config 0
execute if score @s ybih.id matches 12 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp12 ybih.config 0
execute if score @s ybih.id matches 13 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp13 ybih.config 0
execute if score @s ybih.id matches 14 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp14 ybih.config 0
execute if score @s ybih.id matches 15 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp15 ybih.config 0
execute if score @s ybih.id matches 16 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp16 ybih.config 0
execute if score @s ybih.id matches 17 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp17 ybih.config 0
execute if score @s ybih.id matches 18 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp18 ybih.config 0
execute if score @s ybih.id matches 19 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp19 ybih.config 0
execute if score @s ybih.id matches 20 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp20 ybih.config 0
execute if score @s ybih.id matches 21 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp21 ybih.config 0
execute if score @s ybih.id matches 22 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp22 ybih.config 0
execute if score @s ybih.id matches 23 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp23 ybih.config 0
execute if score @s ybih.id matches 24 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp24 ybih.config 0
execute if score @s ybih.id matches 25 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp25 ybih.config 0
execute if score @s ybih.id matches 26 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp26 ybih.config 0
execute if score @s ybih.id matches 27 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp27 ybih.config 0
execute if score @s ybih.id matches 28 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp28 ybih.config 0
execute if score @s ybih.id matches 29 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp29 ybih.config 0
execute if score @s ybih.id matches 30 if score #bp_due ybih.config matches 1.. run scoreboard players set #bp30 ybih.config 0
