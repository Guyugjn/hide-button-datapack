# ybih:button/found_one —— 一位搜寻者找到了按钮：按「还剩几个搜寻者没找到」给分

scoreboard players operation #gained ybih.config = #seekers_left ybih.config
scoreboard players add @s ybih.finds 1
execute if score @s ybih.finds matches 1 run scoreboard players operation @s ybih.t_first = #tick ybih.config
scoreboard players operation @s ybih.score += #seekers_left ybih.config
scoreboard players set @s ybih.found 1
scoreboard players add #found_seq ybih.config 1
scoreboard players remove #seekers_left ybih.config 1
playsound minecraft:entity.player.levelup player @a ~ ~ ~ 1 1.5
tellraw @a [{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 第 {{TXT_E}},{{SCORE_FOUNDSEQ}},{{TXT_S}} 个找到，+{{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #seekers_left ybih.config matches ..0 run function ybih:game/end_round
