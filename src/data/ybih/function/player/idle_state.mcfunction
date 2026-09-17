# ybih:player/idle_state —— 空闲态：摘掉对局标签，效果留给 buff_guard 继续维持

execute if entity @s[tag=ybih_player] run function ybih:player/leave_game
