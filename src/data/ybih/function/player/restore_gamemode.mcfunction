# ybih:player/restore_gamemode —— 按 ybih_gm_* 记录还原玩家本来的游戏模式
# 执行者是被还原的那位玩家
#
# 三条都带 gamemode=spectator 前置：先命中的那条会把人切出旁观，后面的不再命中，
# 所以「身上至多只有一个 ybih_gm_*」是这里正确性的前提（记录点见 player/join_game、
# player/spectate、player/showcase_state，三处都是先清三个再按实际模式补一个）。
# 够不到任何一条的人保持旁观不动 —— 服主自己设的旁观没有记录，程序不替他做决定。
# 三个记录点都只在「他还不是旁观」时开记录，所以记录里存的一定是能正常玩下去的模式
#
# 还原之后把记录一并摘掉：这份记录是「本局接管过他的模式」的凭据，用掉就该失效。
# 留着的话，他离局后自己切旁观会被下一 tick 莫名拽回冒险
#
# 由 player/idle_state 在 #state=0 每 tick 调用一次（on_join 本身每 tick 跑），
# 收的是「整局结束时他不在线」的那类人：
# 收尾点用的全是 @a，够不到离线的人，而他身上那份旁观连同记录一起进了存档；
# 旁观模式不能自己执行 /gamemode（管理员可以用命令，普通玩家下不了场），
# 不在这里兜住，普通玩家就再也下不了场

execute if entity @s[gamemode=spectator,tag=ybih_gm_creative] run gamemode creative @s
execute if entity @s[gamemode=spectator,tag=ybih_gm_survival] run gamemode survival @s
execute if entity @s[gamemode=spectator,tag=ybih_gm_adventure] run gamemode adventure @s
tag @s remove ybih_gm_survival
tag @s remove ybih_gm_creative
tag @s remove ybih_gm_adventure
