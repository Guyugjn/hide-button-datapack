# ybih:room/info —— 把房里每个等待者交给 info_one 逐个刷信息

execute at @e[tag=ybih_room,limit=1] as @a[tag=ybih_player,tag=!ybih_current,distance=..12] run function ybih:room/info_one
