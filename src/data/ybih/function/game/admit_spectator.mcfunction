# ybih:game/admit_spectator —— 在有空位时恢复被数据包接管的观众并让其入队
function ybih:player/restore_gamemode
execute unless entity @s[gamemode=spectator] run function ybih:player/join_game
