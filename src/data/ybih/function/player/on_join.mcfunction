# ybih:player/on_join —— 每 tick 幂等接管在线玩家
# #state=4（轮末围观）时也要接管：围观会把参与者切成旁观并反复传送，
# 这个阶段进来或重连的人若不接管，就会既不在传送范围、也不在任何清理与恢复范围内

# 超时欠账：藏匿者掉线时 game/turn_timeout 的两条结算选择器都选不中他（@a 只遍历在线玩家），
# 于是分没扣、ybih.turn 也没置位。超时那一刻把他的编号记进 #hide_owed，等他回到线上自己来还。
#
# 结账点只能在这里。账主身上始终带着 ybih_player —— 摘这个标签的命令全是 @a 作用域，
# 够不到离线的人，所以他重连时「有标签」这件事认不出他是重连的，
# 按标签判「该补账」的分支永远命中不了。这里是无条件遍历在线玩家的，
# 编号对上就当场结清，不依赖任何在离线期间没法维护的状态
#
# 只在局内结：局外的分数与 ybih.turn 都已作废。#hide_owed 会在下一局开局
# （game/start_begin）连同 #hide_id 一起归零，所以上一局的旧欠账不会跨局
# 误扣新局里恰好抽到同一编号的人
execute if score #state ybih.config matches 1..4 if score @s ybih.id matches 1.. if score @s ybih.id = #hide_owed ybih.config run scoreboard players remove @s ybih.score 1
execute if score #state ybih.config matches 1..4 if score @s ybih.id matches 1.. if score @s ybih.id = #hide_owed ybih.config run scoreboard players set @s ybih.turn 1
execute if score #state ybih.config matches 1..4 if score @s ybih.id matches 1.. if score @s ybih.id = #hide_owed ybih.config run scoreboard players set #hide_owed ybih.config 0

execute if score #state ybih.config matches 1..3 run function ybih:player/active_state
execute if score #state ybih.config matches 4 run function ybih:player/showcase_state
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
