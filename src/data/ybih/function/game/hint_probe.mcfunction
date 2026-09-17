# ybih:game/hint_probe —— 判断该按钮是否属于别人

execute unless score @s ybih.owner_id = #hint_self ybih.config run scoreboard players set #hint_hit ybih.config 1
