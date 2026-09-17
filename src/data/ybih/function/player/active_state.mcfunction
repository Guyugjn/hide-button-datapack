# ybih:player/active_state —— 对局中：有 id 的恢复参与，其余转旁观
# 轮流模式的藏匿者在搜寻期是旁观，不能被强行拉回冒险模式

execute unless entity @s[tag=ybih_player] if score @s ybih.id matches 1.. run function ybih:player/rejoin
execute unless entity @s[tag=ybih_player] unless entity @s[gamemode=spectator] run function ybih:player/spectate
execute if entity @s[tag=ybih_player] unless entity @s[tag=ybih_current] unless entity @s[gamemode=adventure] run gamemode adventure @s
