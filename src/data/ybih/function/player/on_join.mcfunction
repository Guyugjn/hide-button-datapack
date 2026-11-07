# ybih:player/on_join —— 每 tick 幂等接管在线玩家
# #state=4（轮末围观）时也要接管：围观会把参与者切成旁观并反复传送，
# 这个阶段进来或重连的人若不接管，就会既不在传送范围、也不在任何清理与恢复范围内

# 缺少局次或局次不匹配的参赛凭据不属于当前局。必须在欠账结算前清理，
# 防止旧编号与当前局玩家相撞、替他还账；没有局次的旧存档也按过期处理。
execute if score #state ybih.config matches 1..4 if entity @s[tag=ybih_player] unless score @s ybih.era = #era ybih.config run function ybih:player/stale_identity

# 超时欠账：藏匿者掉线时 game/turn_timeout 的两条结算选择器都选不中他（@a 只遍历在线玩家），
# 于是分没扣、ybih.turn 也没置位。超时那一刻把那一笔按位记进 #owed（挂在 ybih.config 上的位图），
# 等他回到线上自己来还。
#
# 整段先由「账上有没有钱」挡一道：这里每 tick 对每个在线玩家跑一遍，
# 而欠账极少发生，没欠账时不该陪着跑那几十条位掩码分派。
# 结账的细节（暂存归零、位掩码、取模、三条动作）都在 player/owed_settle 里
execute if entity @s[tag=ybih_player] if score #owed ybih.config matches 1.. run function ybih:player/owed_settle
# 只向本局身份结清本局账本；局外或旧局身份不可领取。
execute if score #state ybih.config matches 1..4 if score #bp_sum ybih.config matches 1.. if score #bp_era ybih.config = #era ybih.config if entity @s[tag=ybih_player] if score @s ybih.era = #era ybih.config run function ybih:player/bonus_settle

# 欠账可能写入已藏状态，因此必须先还账、再按轮次清理过期状态。
execute if score #state ybih.config matches 1..4 if entity @s[tag=ybih_player] if score #mode ybih.config matches 1 unless score @s ybih.t_epoch = #round ybih.config run function ybih:player/turn_reconcile
execute if score #state ybih.config matches 1..4 if entity @s[tag=ybih_player] if score #mode ybih.config matches 2 unless score @s ybih.t_epoch = #cycle ybih.config run function ybih:player/turn_reconcile

execute if score #state ybih.config matches 1..3 run function ybih:player/active_state
execute if score #state ybih.config matches 4 run function ybih:player/showcase_state
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
