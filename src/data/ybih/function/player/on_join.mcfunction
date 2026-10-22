# ybih:player/on_join —— 每 tick 幂等接管在线玩家
# #state=4（轮末围观）时也要接管：围观会把参与者切成旁观并反复传送，
# 这个阶段进来或重连的人若不接管，就会既不在传送范围、也不在任何清理与恢复范围内

# 超时欠账：藏匿者掉线时 game/turn_timeout 的两条结算选择器都选不中他（@a 只遍历在线玩家），
# 于是分没扣、ybih.turn 也没置位。超时那一刻把那一笔按位记进 #owed（挂在 ybih.config 上的位图），
# 等他回到线上自己来还。
#
# 整段先由「账上有没有钱」挡一道：这里每 tick 对每个在线玩家跑一遍，
# 而欠账极少发生，没欠账时不该陪着跑那几十条位掩码分派。
# 结账的细节（暂存归零、位掩码、取模、三条动作）都在 player/owed_settle 里
execute if score #owed ybih.config matches 1.. run function ybih:player/owed_settle

execute if score #state ybih.config matches 1..3 run function ybih:player/active_state
execute if score #state ybih.config matches 4 run function ybih:player/showcase_state
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
