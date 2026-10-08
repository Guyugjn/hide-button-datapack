# ybih:room/second_tick —— 等待室的每秒调度：刷新等待信息、推进棋局、按节拍撒粒子
# 由 game/second_tick 在 #state 2 每秒调用一次，房内没人时下面几条守卫都会落空

# 房里没人就把粒子节拍归零，下一位进来时立刻能看到第一缕
execute at @e[tag=ybih_room,limit=1] unless entity @a[tag=ybih_player,tag=!ybih_current,distance=..12] run scoreboard players set #room_timer ybih.config 0
# 有人在房里才刷信息栏
execute at @e[tag=ybih_room,limit=1] if entity @a[tag=ybih_player,tag=!ybih_current,distance=..12] run function ybih:room/info
# 棋局每秒核对一次：对手还在不在、两边说法一致不一致，对不上就把那一局作废
execute at @e[tag=ybih_room,limit=1] if entity @a[tag=ybih_player,tag=!ybih_current,distance=..12] run function ybih:room/ttt_tick
# 粒子每 2 秒一次，只在有人在房里时放
scoreboard players remove #room_timer ybih.config 1
execute if score #room_timer ybih.config matches ..0 at @e[tag=ybih_room,limit=1] if entity @a[tag=ybih_player,tag=!ybih_current,distance=..12] run function ybih:room/sparkle
