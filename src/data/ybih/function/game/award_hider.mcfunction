# ybih:game/award_hider —— 轮流模式：藏匿者拿走没人找到的那一份

execute if score #seekers_left ybih.config matches 1.. as @a[tag=ybih_current] run tellraw @s [{{TXT_S}}还有 {{TXT_E}},{{SCORE_SEEKERS}},{{TXT_S}} 人没找到，+{{TXT_E}},{{SCORE_SEEKERS}},{{TXT_S}} 分{{TXT_M}}green{{TXT_E}}]
execute as @a[tag=ybih_current] run scoreboard players operation @s ybih.score += #seekers_left ybih.config
