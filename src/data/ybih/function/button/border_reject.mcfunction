# ybih:button/border_reject —— 贴边界的放置作废：退回材质、清掉方块与标记，并提示
# 必须先退材质再删标记，退回靠的是 ybih_pending 与材质标签

tellraw @s {{TXT_S}}太贴着边界了，按钮已退回，往里挪一点再放{{TXT_M}}red{{TXT_E}}
playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8
function ybih:button/refund_pending
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending
