# ybih:game/rank_step —— 挑出当前最优者、播报名次、打上已排名标记，直到人人有名次
# 排序依据：分数 → 发现次数 → 首次发现时刻 → id，id 唯一所以不会并列

scoreboard players set #best_score ybih.config -2147483648
scoreboard players set #best_finds ybih.config -1
scoreboard players set #best_tfirst ybih.config 999999
scoreboard players set #best_id ybih.config 0
tag @a remove ybih_top
execute as @a[tag=ybih_player,tag=!ybih_ranked] run function ybih:game/rank_scan
execute as @a[tag=ybih_player,tag=!ybih_ranked] run function ybih:game/rank_mark
scoreboard players add #ranked ybih.config 1
execute as @a[tag=ybih_top] run tellraw @a [{{TXT_S}}第 {{TXT_E}},{{SCORE_RANK}},{{TXT_S}} 名：{{TXT_E}},{{SEL_S}}@s{{SEL_E}},{{TXT_S}} — {{TXT_E}},{{SCORE_SELF}},{{TXT_S}} 分 · 发现 {{TXT_E}},{{SCORE_FINDS}},{{TXT_S}} 次{{TXT_M}}gold{{TXT_E}}]
tag @a[tag=ybih_top] add ybih_ranked
tag @a remove ybih_top
execute if entity @a[tag=ybih_player,tag=!ybih_ranked] run function ybih:game/rank_step
