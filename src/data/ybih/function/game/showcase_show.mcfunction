# ybih:game/showcase_show —— 把全体带到这个按钮跟前
# 执行者是待展示按钮的标记实体，观看位置由 showcase_view 按朝向算
# ybih_ghost 代表这个按钮的分已经被拿完、方块收走了，Boss 栏与标题要分开说

tag @s add ybih_shown
# 记录「当前正在展示的是哪一个」：定格期间 showcase_tick 要每 tick 找到它按人回站位。
# ybih_shown 是累积的（展示过的都带着，直到下一轮才清），拿它去 limit=1 取到的是
# 最早展示过的那一个，会让定格一直把人按回第一个按钮的位置
tag @e[tag=ybih_showing] remove ybih_showing
tag @s add ybih_showing
scoreboard players set #show_found ybih.config 0
execute if entity @s[tag=ybih_ghost] run scoreboard players set #show_found ybih.config 1
# 高亮要排在 Boss 栏之前：#show_found 在这里定下来，配色和文案都照它分派
function ybih:game/showcase_glow
function ybih:game/showcase_bar
function ybih:game/showcase_view
# 传送的瞬间玩家可能还按着方向键，客户端会按原来的速度继续预测位移，
# 于是刚落地就顺着原方向飞出去。接下来 20 tick 由 showcase_pin 每 tick 把人按回站位
scoreboard players operation #freeze ybih.config = #c20 ybih.config
