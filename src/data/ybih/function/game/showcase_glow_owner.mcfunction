# ybih:game/showcase_glow_owner —— 给当前按钮的物主上同色（执行者是那位玩家）
# 先退掉两个队再进：玩家可能还留着上一轮展示时的队伍，不退的话会同属两队，
# 轮廓颜色取哪个队是不确定的
#
# 由 showcase_glow 在「这个标记的 owner_id 等于 @s 的 id」时才调用，
# #show_found 此时已经置好，直接照它分派

team leave @s
execute if score #show_found ybih.config matches 1 run team join ybih_found @s
execute if score #show_found ybih.config matches 0 run team join ybih_notfound @s
effect give @s minecraft:glowing 999999 0 true

# 挂个标签把物主钉住：Boss 栏每秒刷新时要重新写出他的名字，
# 而那一刻已经没有标记可依，只能靠这个标签把物主找回来
tag @s add ybih_show_owner
function ybih:game/showcase_bar_owner
