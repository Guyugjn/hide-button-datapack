# ybih:button/reject_unknown —— 待确认的位置材质不在本包清单内：不作数
# 能被识别成"未知材质"的位置，玩家手里不可能有该材质，所以不退回任何物品

tellraw @s {{TXT_S}}这个位置不能用，请换个地方放按钮{{TXT_M}}red{{TXT_E}}
playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8
execute as @e[tag=ybih_pending,tag=ybih_unknown] run function ybih:button/drop_pending
