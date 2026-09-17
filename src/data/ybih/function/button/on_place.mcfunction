# ybih:button/on_place —— 放置方块触发入口（advancement 奖励函数）
# 只有当前轮次的藏匿者、且本回合还没藏过，才会注册

execute if score #state ybih.config matches 2 if entity @s[tag=ybih_current] unless score @s ybih.placed matches 1 run function ybih:button/try_register
advancement revoke @s only ybih:button_placed
