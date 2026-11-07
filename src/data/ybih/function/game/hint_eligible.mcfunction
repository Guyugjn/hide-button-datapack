# ybih:game/hint_eligible —— 判断按钮是否可供当前玩家取分
# 执行者是按钮标记；#hint_self、#hit_bit、#hit_pow 由 hint_one 准备。
# 距离扫描与方位候选共用此判据，避免两者指向不同目标。

scoreboard players set #hint_ok ybih.config 0
scoreboard players set #hint_hit ybih.config -1
execute if score #hit_bit ybih.config matches 1.. unless score @s ybih.owner_id = #hint_self ybih.config if score @s ybih.value matches 1.. run scoreboard players operation #hint_hit ybih.config = @s ybih.hit
execute if score #hint_hit ybih.config matches 0.. if score #hit_pow ybih.config matches 1.. run scoreboard players operation #hint_hit ybih.config %= #hit_pow ybih.config
execute if score #hint_hit ybih.config matches 0.. if score #hint_hit ybih.config < #hit_bit ybih.config run scoreboard players set #hint_ok ybih.config 1
