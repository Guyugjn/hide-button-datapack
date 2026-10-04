# ybih:game/showcase_glow —— 把当前这一个按钮、以及它的物主标成同一个颜色
# 执行者是待展示按钮的标记实体
#
# 发光轮廓的颜色由实体所属队伍的 color 决定，所以要靠队伍上色。
# 只亮当前这一个：每次切换先整批清掉，再给当前这个挂上 ——
# 不用记「上一个是谁」，清光的动作本身就把它带走了
#
# 分被拿完用红队、还有分用绿队。玩家只在自己那个按钮被展示时临时进队、之后退出，
# 所以同屏最多只有「当前按钮 + 它的物主」两处发光

# 先整批清掉上一轮的高亮。玩家只清参与者：没参与对局的人不进队，
# 也不该被围观顺手清掉自己的发光
effect clear @e[tag=ybih_showcase] minecraft:glowing
effect clear @a[tag=ybih_player] minecraft:glowing
# 上一个物主的标签也要撤，否则 Boss 栏会继续写他的名字
tag @a remove ybih_show_owner
team leave @a[tag=ybih_player]

execute if entity @s[tag=ybih_ghost] run team join ybih_found @s
execute unless entity @s[tag=ybih_ghost] run team join ybih_notfound @s
effect give @s minecraft:glowing 999999 0 true

# 物主也标成同色，方便一眼看出这个按钮是谁藏的
scoreboard players operation #show_owner ybih.config = @s ybih.owner_id
execute as @a[tag=ybih_player] if score @s ybih.id = #show_owner ybih.config run function ybih:game/showcase_glow_owner
