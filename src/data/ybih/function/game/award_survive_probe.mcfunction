# ybih:game/award_survive_probe —— 该按钮是否属于当前玩家

execute if score @s ybih.owner_id = #survive_self ybih.config run scoreboard players set #survive_hit ybih.config 1
