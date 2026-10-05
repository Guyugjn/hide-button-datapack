# ybih:player/active_state —— 对局中：有 id 的恢复参与，其余转旁观
# 轮流模式的藏匿者在搜寻期是旁观，不能被强行拉回冒险模式

# 入队的人不一定领到过对局保险：game/start_begin 只在开局那一 tick 给全体发一次，
# 中途补进对局的人（game/next_round 调 player/join_game）赶不上那一趟，
# 而 player/buff_guard 只对已带 ybih_buffed 的人续期，发不出第一份。
# 这里每 tick 自省一次补上；掉线重连的人错过的也正是这一份
execute if entity @s[tag=ybih_player] unless entity @s[tag=ybih_buffed] run function ybih:player/apply_buff

# 对局中进来又没有 id 的人是旁观者：转旁观、给夜视、送到观战位
execute unless entity @s[tag=ybih_player] unless entity @s[gamemode=spectator] run function ybih:player/spectate
execute if entity @s[tag=ybih_player] unless entity @s[tag=ybih_current] unless entity @s[gamemode=adventure] run gamemode adventure @s
