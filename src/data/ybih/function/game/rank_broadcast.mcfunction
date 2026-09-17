# ybih:game/rank_broadcast —— 从第一名开始逐个播报完整名次

tag @a remove ybih_ranked
tag @a remove ybih_top
scoreboard players set #ranked ybih.config 0
function ybih:game/rank_step
