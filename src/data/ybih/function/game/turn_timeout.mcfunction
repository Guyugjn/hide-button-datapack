# ybih:game/turn_timeout —— 藏匿超时：扣 1 分，本回合作废
#
# 藏匿者可能在这一回合中途掉线。@a 选不中离线玩家，按标签找人的写法会整体落空，
# 他重连后 ybih.turn 仍是 0，下一轮又被选中一次。
# 所以改用 turn_next 在他还在线时记下的编号 #hide_id 去找人，并在下面先探一次他在不在线：
# 在线就当场扣分置位；不在线则把编号记进欠账位图，等他重连时由 player/on_join 补还。
# 编号为 0（没人轮到时）匹配不上任何玩家 —— ybih.id 从 1 起分配

execute if entity @e[tag=ybih_pending] run tellraw @a {{TXT_S}}[藏匿超时] 按钮没有确认，扣 1 分{{TXT_M}}yellow{{TXT_E}}
execute unless entity @e[tag=ybih_pending] run tellraw @a {{TXT_S}}[藏匿超时] 该玩家没有放按钮，扣 1 分{{TXT_M}}yellow{{TXT_E}}

# 先探一遍目标在不在线。@a 只遍历在线玩家，探不到就说明他掉线了
scoreboard players set #hide_found ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.id=1..}] if score @s ybih.id = #hide_id ybih.config run scoreboard players set #hide_found ybih.config 1

# 在线者当场结清
execute as @a[tag=ybih_player,scores={ybih.id=1..}] if score @s ybih.id = #hide_id ybih.config run scoreboard players remove @s ybih.score 1
execute as @a[tag=ybih_player,scores={ybih.id=1..}] if score @s ybih.id = #hide_id ybih.config run scoreboard players set @s ybih.turn 1

# 探不到人：这次结算两条都落空了，把编号记成欠账，等他重连自己来还。
# 记分板的分数持有者条目对离线玩家一样存在，但他的名字只有他自己回来时才拿得到 ——
# 在线的 @a 选择器永远选不中他，所以只能反过来由他来找这笔账。
#
# 欠账是**位图**（ybih.owed，位号 = 编号 - 1），不是「一个编号占一格」：
# 后者在连续两次「超时且掉线」时，后一笔会把前一笔顶掉，先欠的那位白逃一分。
# 位图按位或累加（下一行）、按位减结清（player/on_join），两笔互不影响
execute if score #hide_found ybih.config matches 0 run scoreboard players operation #owed_src ybih.config = #hide_id ybih.config
execute if score #hide_found ybih.config matches 0 run function ybih:game/owed_bit
execute if score #owed_bit ybih.config matches 1.. run scoreboard players operation #owed ybih.config += #owed_bit ybih.config

execute as @a[tag=ybih_current] run clear @s #minecraft:buttons
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending

execute if score #mode ybih.config matches 1 run function ybih:game/turn_advance
execute if score #mode ybih.config matches 2 run function ybih:game/turn_timeout_mode2
