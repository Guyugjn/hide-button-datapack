# ybih:game/rank_scan —— 与当前最优者比较：分数 → 发现次数 → 首次发现时刻 → id

execute if score @s ybih.score > #best_score ybih.config run function ybih:game/rank_take
execute if score @s ybih.score = #best_score ybih.config if score @s ybih.finds > #best_finds ybih.config run function ybih:game/rank_take
execute if score @s ybih.score = #best_score ybih.config if score @s ybih.finds = #best_finds ybih.config if score @s ybih.t_first < #best_tfirst ybih.config run function ybih:game/rank_take
execute if score @s ybih.score = #best_score ybih.config if score @s ybih.finds = #best_finds ybih.config if score @s ybih.t_first = #best_tfirst ybih.config if score @s ybih.id < #best_id ybih.config run function ybih:game/rank_take
