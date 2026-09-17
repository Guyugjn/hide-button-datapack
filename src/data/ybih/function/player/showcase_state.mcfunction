# ybih:player/showcase_state —— 围观阶段（#state=4）接管在线玩家
# 围观会把参与者切旁观并一起传送。这个阶段进来或重连的人要享受同等待遇，
# 否则他会以冒险模式留在原地，既看不到展示、又在围观结束时不在任何清理范围内
#
# 只接管「还没被围观接管过」的人：已经带 ybih_show_nv 的说明上一 tick 或
# showcase_start 已经处理过，不必每 tick 重设旁观与重发夜视 ——
# 那会把手感打断，也会把玩家自己喝的夜视反复覆盖
#
# 原游戏模式照 join_game 那套记下来，showcase_end 才能还原成他本来的模式。
# 只记一次（未带标记时），免得第二轮把已经切成的 spectator 记进去，收尾就还原不回去

execute unless entity @s[tag=ybih_show_nv] unless entity @s[gamemode=spectator] run tag @s remove ybih_gm_survival
execute unless entity @s[tag=ybih_show_nv] unless entity @s[gamemode=spectator] run tag @s remove ybih_gm_creative
execute unless entity @s[tag=ybih_show_nv] unless entity @s[gamemode=spectator] run tag @s remove ybih_gm_adventure
execute unless entity @s[tag=ybih_show_nv] if entity @s[gamemode=survival] run tag @s add ybih_gm_survival
execute unless entity @s[tag=ybih_show_nv] if entity @s[gamemode=creative] run tag @s add ybih_gm_creative
execute unless entity @s[tag=ybih_show_nv] if entity @s[gamemode=adventure] run tag @s add ybih_gm_adventure

execute unless entity @s[tag=ybih_show_nv] run gamemode spectator @s
execute unless entity @s[tag=ybih_show_nv] run effect give @s minecraft:night_vision 999999 0 true
execute unless entity @s[tag=ybih_show_nv] run tag @s add ybih_show_nv
