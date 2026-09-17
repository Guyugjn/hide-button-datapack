# ybih:player/leave_room —— 把还留在等待室里的人送回集合点
# 阶段切换只在那一个瞬间执行 tp，掉线期间人在等待室的重连者需要这条兜底

execute if entity @e[tag=ybih_center] if entity @e[tag=ybih_room] at @e[tag=ybih_room,limit=1] if entity @s[distance=..12] run tp @s @e[tag=ybih_center,limit=1]
