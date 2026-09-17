# ybih:game/turn_timeout —— 藏匿超时：扣 1 分，本回合作废
#
# 藏匿者可能在这一回合中途掉线。@a 选不中离线玩家，用标签找人的写法会整体落空，
# 他重连后 ybih.turn 仍是 0，下一轮又被选中一次。
# 所以改用 turn_next 在他还在线时记下的编号 #hide_id 去找人：
# 记分板的分数持有者条目对离线玩家一样存在，按编号写分照样生效。
# 编号为 0（没人轮到时）匹配不上任何玩家 —— ybih.id 从 1 起分配

execute if entity @e[tag=ybih_pending] run tellraw @a {{TXT_S}}[藏匿超时] 按钮没有确认，扣 1 分{{TXT_M}}yellow{{TXT_E}}
execute unless entity @e[tag=ybih_pending] run tellraw @a {{TXT_S}}[藏匿超时] 该玩家没有放按钮，扣 1 分{{TXT_M}}yellow{{TXT_E}}

# 按编号扣分与置位：对已掉线的藏匿者也生效
execute as @a[tag=ybih_player,scores={ybih.id=1..}] if score @s ybih.id = #hide_id ybih.config run scoreboard players remove @s ybih.score 1
execute as @a[tag=ybih_player,scores={ybih.id=1..}] if score @s ybih.id = #hide_id ybih.config run scoreboard players set @s ybih.turn 1

execute as @a[tag=ybih_current] run clear @s #minecraft:buttons
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending

execute if score #mode ybih.config matches 1 run function ybih:game/turn_advance
execute if score #mode ybih.config matches 2 run function ybih:game/turn_timeout_mode2
