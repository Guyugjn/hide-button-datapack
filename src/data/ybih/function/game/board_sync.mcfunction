# ybih:game/board_sync —— 让右侧榜单只列当前在线的玩家
# 真实分数始终记在 ybih.score 里；侧边栏看的是镜像榜 ybih.board，
# 所以玩家退出只是从榜上消失，分数不丢，重连回来分数照旧

scoreboard players set #board_timer ybih.config 20

# 在线人数与在场 id 之和任一变化就说明有人进出，这时整榜重建一次：
# reset * 会把离线玩家遗留的行一并清掉（* 代表记分板上所有记过分的名字，
# 不受在线与否影响），紧接着再把当前在线的人写回去
scoreboard players set #online_now ybih.config 0
scoreboard players set #online_sum ybih.config 0
execute as @a run scoreboard players add #online_now ybih.config 1
execute as @a run scoreboard players operation #online_sum ybih.config += @s ybih.id
execute unless score #online_now ybih.config = #online_prev ybih.config run scoreboard players reset * ybih.board
execute unless score #online_sum ybih.config = #online_sum_prev ybih.config run scoreboard players reset * ybih.board
scoreboard players operation #online_prev ybih.config = #online_now ybih.config
scoreboard players operation #online_sum_prev ybih.config = #online_sum ybih.config

# 兜底：每 #board_gc 秒无条件重建一次。离线拿不到可靠信号（* 只能用在 reset 上，
# 没法逐个持有人查询），一进一出恰好落在两次采样之间、两个快照又没变时上一步会漏掉
scoreboard players remove #board_gc ybih.config 1
execute if score #board_gc ybih.config matches ..0 run scoreboard players reset * ybih.board
execute if score #board_gc ybih.config matches ..0 run scoreboard players set #board_gc ybih.config 10
