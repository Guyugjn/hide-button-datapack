# ybih:button/give_up —— 反复被破坏的按钮：收回它、修掉计数、通知物主
# 水这类东西会一次次把按钮冲掉，而保护机制每恢复一次就掉落一个按钮物品，
# 数到上限说明这个位置保不住，不再陪它循环
# 执行者是按钮标记

scoreboard players operation #fix_owner ybih.config = @s ybih.owner_id
# 只减到 0 为止：还没被计数过的标记（待确认、地图自带）也在 ybih_button 里，
# 照着减会把 #button_count 带成负数，搜寻阶段开局即判定「已按完」
execute if score #button_count ybih.config matches 1.. run scoreboard players remove #button_count ybih.config 1
execute as @a if score @s ybih.id = #fix_owner ybih.config run tellraw @s {{TXT_S}}你的按钮被水或爆炸反复冲毁，已经收回；下次换个地方藏{{TXT_M}}red{{TXT_E}}
execute as @a if score @s ybih.id = #fix_owner ybih.config run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8
kill @s
