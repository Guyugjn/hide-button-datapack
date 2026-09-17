# ybih:game/showcase_start —— 进入围观阶段：把本局按钮摘出对局管理，全体转旁观
# 摘掉 ybih_button 之后，清场、保护、按下检测都不再管它们
# ybih_ghost 保留着不摘：它是「这个按钮当时被找到了」的判据，showcase_bar 要靠它换文案

scoreboard players set #state ybih.config 4
scoreboard players set #show_idx ybih.config 0
scoreboard players set #show_timer ybih.config 1

# 先挂展示标签再摘对局标签：反过来的话第二轮就选不中它们了
execute as @e[tag=ybih_button] if score @s ybih.era = #era ybih.config run tag @s add ybih_showcase
execute as @e[tag=ybih_ghost] if score @s ybih.era = #era ybih.config run tag @s add ybih_showcase
execute as @e[tag=ybih_showcase] run tag @s remove ybih_button
# 出场顺序靠「还没展示过」来挑，这里先把可能残留的展示标记清掉
execute as @e[tag=ybih_showcase] run tag @s remove ybih_shown
execute as @e[tag=ybih_showing] run tag @s remove ybih_showing

# 被按掉的按钮把方块摆回去，用的就是保护机制那套「按材质与朝向还原」。
# 只在那一格是空气时动手：万一玩家后来在旧位置放了别的方块，
# 覆盖上去、围观结束再清成空气，就等于平白删了他一个方块
# 还要先过一遍水的检查：按钮存不住水，摆回去当场就会被冲掉、掉落一个按钮物品
execute as @e[tag=ybih_showcase,tag=ybih_ghost] at @s if block ~ ~ ~ minecraft:air run function ybih:game/showcase_restore

# 围观是隔着上百格来回传送的。玩家一走，上一个按钮的区块就卸载，
# 标记随即从 @e 的视野里消失、还剩几个也无从判断，队列会当场断掉。
# 把待展示按钮所在的区块钉住，等展示完再放开
# confirm_place_ok / consume 已经钉过绝大多数，这里只给漏网的补一次。
# 统一用 ybih_pinned 作凭据，showcase_end 与 cleanup_all 按它释放
execute as @e[tag=ybih_showcase,tag=!ybih_pinned] at @s run forceload add ~ ~
tag @e[tag=ybih_showcase] add ybih_pinned

# 参与者进围观：记下「夜视是围观给的」，收尾时照这个标记清，
# 免得把没参与这局的人自己喝的夜视一并清掉
tag @a[tag=ybih_player] add ybih_show_nv
gamemode spectator @a[tag=ybih_player]
effect give @a[tag=ybih_player] minecraft:night_vision 999999 0 true
tellraw @a [{{TXT_S}}本轮一共 {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} 个按钮，带大家看一遍都藏在哪{{TXT_M}}gold{{TXT_E}}]
