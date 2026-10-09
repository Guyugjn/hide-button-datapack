# ybih:player/on_join —— 每 tick 幂等接管在线玩家
# #state=4（轮末围观）时也要接管：围观会把参与者切成旁观并反复传送，
# 这个阶段进来或重连的人若不接管，就会既不在传送范围、也不在任何清理与恢复范围内

# 超时欠账：藏匿者掉线时 game/turn_timeout 的两条结算选择器都选不中他（@a 只遍历在线玩家），
# 于是分没扣、ybih.turn 也没置位。超时那一刻把那一笔按位记进 #owed（挂在 ybih.config 上的位图），
# 等他回到线上自己来还。
#
# 结账点只能在这里。账主身上始终带着 ybih_player —— 摘这个标签的命令全是 @a 作用域，
# 够不到离线的人，所以他重连时「有标签」这件事认不出他是重连的，
# 按标签判「该补账」的分支永远命中不了。这里是无条件遍历在线玩家的，
# 编号对上就当场结清，不依赖任何在离线期间没法维护的状态
#
# 只在局内结：局外的分数与 ybih.turn 都已作废。#owed 会在下一局开局
# （game/start_begin）连同 #hide_id 一起归零，所以上一局的旧欠账不会跨局
# 误扣新局里恰好抽到同一编号的人
#
# 判定用的是位图取模，与 button/award_grant 同一套：编号 > 30 时 #owed_bit 为 0，
# 那种人本来就记不进账（与位图上限一致），这里自然跳过。
#
# 整段先由「账上有没有钱」挡一道：这里每 tick 对每个在线玩家跑一遍，
# 而欠账极少发生，没欠账时不该陪着跑那六十条位掩码分派。
# 两个暂存必须**无条件**先归零：下面三条动作只看 #owed_bit / #owed_now，
# 而账已结清时这两个值会是上一个人（上一 tick）留下的，照着它们判就会误扣
scoreboard players set #owed_bit ybih.config 0
scoreboard players set #owed_now ybih.config 0
execute if score #owed ybih.config matches 1.. run scoreboard players operation #owed_src ybih.config = @s ybih.id
execute if score #owed ybih.config matches 1.. run function ybih:game/owed_bit
# 取模这一步也带 #owed_bit 的守卫：编号 > 30 时 #owed_pow 是 0，
# 而「对 0 取模」会是一条失败命令，没必要让它出现在函数里
execute if score #owed ybih.config matches 1.. if score #owed_bit ybih.config matches 1.. run scoreboard players operation #owed_now ybih.config = #owed ybih.config
execute if score #owed ybih.config matches 1.. if score #owed_bit ybih.config matches 1.. run scoreboard players operation #owed_now ybih.config %= #owed_pow ybih.config
execute if score #state ybih.config matches 1..4 if score #owed_bit ybih.config matches 1.. if score #owed_now ybih.config >= #owed_bit ybih.config run scoreboard players remove @s ybih.score 1
execute if score #state ybih.config matches 1..4 if score #owed_bit ybih.config matches 1.. if score #owed_now ybih.config >= #owed_bit ybih.config run scoreboard players set @s ybih.turn 1
execute if score #state ybih.config matches 1..4 if score #owed_bit ybih.config matches 1.. if score #owed_now ybih.config >= #owed_bit ybih.config run scoreboard players operation #owed ybih.config -= #owed_bit ybih.config

execute if score #state ybih.config matches 1..3 run function ybih:player/active_state
execute if score #state ybih.config matches 4 run function ybih:player/showcase_state
execute if score #state ybih.config matches 0 run function ybih:player/idle_state
