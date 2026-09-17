# ybih:button/fluid_reject —— 挨着水或岩浆的放置作废：退回材质、清掉方块与标记，并提示
# 必须先退材质再删标记，退回靠的是 ybih_pending 与材质标签

tellraw @s {{TXT_S}}这里在水里或紧挨着水，按钮会被冲走，已退回，换个位置再放{{TXT_M}}red{{TXT_E}}
playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8
function ybih:button/refund_pending
execute as @e[tag=ybih_pending] run function ybih:button/retract_pending
