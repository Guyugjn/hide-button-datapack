# ybih:player/on_join —— 每 tick 幂等接管在线玩家
# #state=4（轮末围观）时也要接管：围观会把参与者切成旁观并反复传送，
# 这个阶段进来或重连的人若不接管，就会既不在传送范围、也不在任何清理与恢复范围内

execute if score #state ybih.config matches 1..3 run function ybih:player/active_state
execute if score #state ybih.config matches 4 run function ybih:player/showcase_state
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
