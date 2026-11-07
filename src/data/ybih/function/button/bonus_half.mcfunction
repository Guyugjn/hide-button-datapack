# ybih:button/bonus_half —— 到最后阶段才第一次被找到：物主拿半份保底分
# 由 button/award_score 在「#first_find = 1 且已进末段」时调进来，执行者是按下者
#
# 规则口径（两档梯度）：
#   一次都没被找到          → 轮末给 N - 1 分
#   到最后三分之一才被找到  → 给 floor((N - 1) / 2) 分，多人局至少 1 分
#   更早被找到              → 0，那份价值已在按下的一刻结清
#
# 为什么当场发、不留到轮末：判据（#first_find 与 #timer）在 award_score 这一刻
# 都已经在手上，留到轮末就得在按钮标记上多存一个「是不是末段才被找到」的状态，
# 那要新开一个记分项、还得让 bonus_run 再遍历一趟。当场发的代价只是时点提前，
# 玩家反而能立刻看到「差一点就藏住了」的反馈
#
# 物主不在线时记入本局账本，本局结束前重连才补发。
# 编号为 0 是「没有编主」而不是有效编号。
#
# #bonus_half 每次进来都重算，不存在复用陈旧值的问题

scoreboard players operation #bonus_half ybih.config = #player_count ybih.config
scoreboard players remove #bonus_half ybih.config 1
scoreboard players operation #bonus_half ybih.config /= #c2 ybih.config
execute if score #player_count ybih.config matches 2.. if score #bonus_half ybih.config matches ..0 run scoreboard players set #bonus_half ybih.config 1

scoreboard players set #bonus_got ybih.config 0
execute if score #bonus_half ybih.config matches 1.. if score #press_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.era = #era ybih.config if score @s ybih.id = #press_owner ybih.config run scoreboard players set #bonus_got ybih.config 1
execute if score #bonus_half ybih.config matches 1.. if score #press_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.era = #era ybih.config if score @s ybih.id = #press_owner ybih.config run scoreboard players operation @s ybih.score += #bonus_half ybih.config
execute if score #bonus_half ybih.config matches 1.. if score #press_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.era = #era ybih.config if score @s ybih.id = #press_owner ybih.config run tellraw @s [{{TXT_S}}你的按钮到最后阶段才被找到，保底分减半，+{{TXT_E}},{{SCORE_BONUS_HALF}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #bonus_half ybih.config matches 1.. if score #bonus_got ybih.config matches 0 if score #press_owner ybih.config matches 1..30 if score #bp_era ybih.config = #era ybih.config run scoreboard players operation #bonus_owner ybih.config = #press_owner ybih.config
execute if score #bonus_half ybih.config matches 1.. if score #bonus_got ybih.config matches 0 if score #press_owner ybih.config matches 1..30 if score #bp_era ybih.config = #era ybih.config run scoreboard players operation #bonus_credit ybih.config = #bonus_half ybih.config
execute if score #bonus_half ybih.config matches 1.. if score #bonus_got ybih.config matches 0 if score #press_owner ybih.config matches 1..30 if score #bp_era ybih.config = #era ybih.config run function ybih:game/bonus_enqueue
