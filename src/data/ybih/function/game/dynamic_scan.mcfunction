# ybih:game/dynamic_scan —— 统计场上所有在线未领取份数

scoreboard players set #dyn_remaining ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.id=1..30}] if score @s ybih.era = #era ybih.config run function ybih:game/dynamic_player
scoreboard players operation #dyn_seen ybih.config = #dyn_mask ybih.config
scoreboard players operation #dyn_round ybih.config = #round ybih.config
scoreboard players set #dyn_dirty ybih.config 0
scoreboard players set #dyn_timer ybih.config 20
