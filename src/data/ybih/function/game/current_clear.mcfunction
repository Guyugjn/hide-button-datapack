# ybih:game/current_clear —— 撤掉藏匿凭据 ybih_current 与它带来的观战夜视
# 执行者是那位玩家
#
# 效果与凭据一起撤，少一样都会留残留：凭据一摘掉，就再也没有哪条命令能选中他
# 去清那份夜视 —— 收尾点用的全是 @a，够不到当时离线的人
#
# 夜视是有条件地清：他同时带着围观夜视（ybih_show_nv）或观战夜视（ybih_spect_nv）时，
# 那份夜视归各自的凭据管。照清不误会留下「凭据还在、效果却先没了」的空档，
# 而这两个凭据的续期点都带着「还没有凭据」的前提（player/showcase_state 的 unless、
# player/buff_guard 的 ybih_spect_nv 分支），补不回来
#
# 由 player/buff_guard 在凭据不成立时每秒调用一次（判据见那里）
#
# 摘凭据**不再**意味着「下一 tick 会有人把他拉回冒险」：每 tick 的游戏模式强推已经取消，
# 模式只在关键节点强制。所以这里的调用方要自己保证收尾：
# 轮流模式的藏匿者本轮结束时由 game/cleanup_buttons 按 ybih_gm_* 记录还原

execute unless entity @s[tag=ybih_show_nv] unless entity @s[tag=ybih_spect_nv] run effect clear @s minecraft:night_vision
tag @s remove ybih_current
