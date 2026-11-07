# ybih:game/dynamic_monitor —— 在线名单或取分变化时复核收官
# 只在搜寻阶段调用；每局首次进入搜寻也必须先扫描。

scoreboard players remove #dyn_timer ybih.config 1
execute if score #dyn_timer ybih.config matches ..0 run scoreboard players set #dyn_dirty ybih.config 1
scoreboard players set #dyn_mask ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.id=1..30}] if score @s ybih.era = #era ybih.config run function ybih:game/dynamic_mask_player
execute unless score #dyn_seen ybih.config = #dyn_mask ybih.config run scoreboard players set #dyn_dirty ybih.config 1
execute unless score #dyn_round ybih.config = #round ybih.config run scoreboard players set #dyn_dirty ybih.config 1
execute if score #dyn_dirty ybih.config matches 1.. run function ybih:game/dynamic_scan
execute if score #dyn_remaining ybih.config matches 0 run function ybih:game/end_round
