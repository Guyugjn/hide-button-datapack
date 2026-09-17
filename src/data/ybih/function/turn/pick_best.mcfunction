# ybih:turn/pick_best —— 取未完成回合玩家中 id 最小者

execute unless score #best ybih.config matches 1.. run scoreboard players operation #best ybih.config = @s ybih.id
execute if score @s ybih.id < #best ybih.config run scoreboard players operation #best ybih.config = @s ybih.id
