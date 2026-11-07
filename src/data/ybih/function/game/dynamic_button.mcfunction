# ybih:game/dynamic_button —— 统计玩家与按钮之间尚未领取的一份
# 执行者是按钮标记；玩家编号和位图掩码由 dynamic_player 提供。

execute if score @s ybih.value matches ..0 run scoreboard players set @s ybih.value 1
scoreboard players set #dyn_hit ybih.config -1
execute unless score @s ybih.owner_id = #dyn_id ybih.config run scoreboard players operation #dyn_hit ybih.config = @s ybih.hit
execute if score #dyn_hit ybih.config matches 0.. run scoreboard players operation #dyn_hit ybih.config %= #hit_pow ybih.config
execute if score #dyn_hit ybih.config matches 0.. if score #dyn_hit ybih.config < #hit_bit ybih.config run scoreboard players add #dyn_remaining ybih.config 1
