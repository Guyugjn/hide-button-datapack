# ybih:button/bonus_half —— 到最后阶段才第一次被找到：物主拿半份保底分
# 由 button/award_score 在「#first_find = 1 且已进末段」时调进来，执行者是按下者
#
# 规则口径（两档梯度）：
#   一次都没被找到          → 轮末由 game/bonus_run 给满份 floor(N / 2)
#   到最后三分之一才被找到  → 这里当场给半份 floor(N / 4)
#   更早被找到              → 0，那份价值已在按下的一刻结清
#
# 为什么当场发、不留到轮末：判据（#first_find 与 #timer）在 award_score 这一刻
# 都已经在手上，留到轮末就得在按钮标记上多存一个「是不是末段才被找到」的状态，
# 那要新开一个记分项、还得让 bonus_run 再遍历一趟。当场发的代价只是时点提前，
# 玩家反而能立刻看到「差一点就藏住了」的反馈
#
# floor(floor(N/2) / 2) 对非负整数恒等于 floor(N/4)，所以这里连除两次 #c2，
# 不必新增 #c4 常量
#
# 物主此刻不在线就整段作废：@a 只遍历在线玩家，与项目里其余一次性收尾点同一口径
# （见 game/bonus_pay）。编号为 0 是「没有编主」而不是一个编号，
# 与 bonus_pay 里 #bonus_owner matches 1.. 同一道理
#
# #bonus_half 每次进来都重算，不存在复用陈旧值的问题

scoreboard players operation #bonus_half ybih.config = #player_count ybih.config
scoreboard players operation #bonus_half ybih.config /= #c2 ybih.config
scoreboard players operation #bonus_half ybih.config /= #c2 ybih.config

execute if score #bonus_half ybih.config matches 1.. if score #press_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run scoreboard players operation @s ybih.score += #bonus_half ybih.config
execute if score #bonus_half ybih.config matches 1.. if score #press_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run tellraw @s [{{TXT_S}}你的按钮到最后阶段才被找到，保底分减半，+{{TXT_E}},{{SCORE_BONUS_HALF}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
