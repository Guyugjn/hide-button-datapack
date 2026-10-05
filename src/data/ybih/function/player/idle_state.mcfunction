# ybih:player/idle_state —— 空闲态：摘掉对局标签
# 效果留给 buff_guard 继续维持；藏匿凭据 ybih_current 与它的观战夜视也归那里成对收掉
#
# 这里额外兜住「整局结束时不在线」的人：他的旁观模式与 ybih_gm_* 记录一起进了存档，
# 而收尾点用的全是 @a，够不到他。凭据一并用掉，免得日后再把他拽回旧模式

function ybih:player/restore_gamemode
execute if entity @s[tag=ybih_player] run function ybih:player/leave_game
