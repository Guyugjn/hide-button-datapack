# ybih:button/award_score —— 位图已落，正式计分
# 执行者是按下者，#gained 是这次拿到的分

scoreboard players operation @s ybih.score += #gained ybih.config
scoreboard players add @s ybih.finds 1
execute if score @s ybih.finds matches 1 run scoreboard players operation @s ybih.t_first = #tick ybih.config
playsound minecraft:entity.player.levelup player @a ~ ~ ~ 1 1.5
tellraw @s [{{TXT_S}}+{{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}green{{TXT_E}}]
function ybih:button/notify_owner
function ybih:button/award_dec
