# ybih:game/dynamic_prepare —— 搜寻开始时初始化在线可领取份数
# 只统计，不在这里结束本轮；由 dynamic_monitor 统一判定收官。

scoreboard players set #dyn_mask ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.id=1..30}] if score @s ybih.era = #era ybih.config run function ybih:game/dynamic_mask_player
function ybih:game/dynamic_scan
