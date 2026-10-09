# ybih:player/leave_game —— 退出对局身份
# 不撤保险效果：它挂到下一次 /reload 为止，中途退出对局也不该掉
#
# 这里**不摘** ybih_current：摘了就等于把观战夜视的追索线索掐断 ——
# 所有以它选人的回收点随即失效，效果只能等自己熄灭。
# 凭据与它的夜视由 player/buff_guard 在 #state 之外统一成对收掉

# 先撤棋盘上的局面，再动编号 —— 顺序不能反：
# ttt_abort 是靠「我的 ybih.id → 对手的编号」找回对手的，编号一归零，
# 那边就成了一局没人收的残局，对手的棋盘一直停在「对局中」，
# 点格子毫无反应，只有他自己点【刷新名单】才能脱身。
# 也不能等到后面几步去收：ttt_tick 的核对分支都带 tag=ybih_player，
# 标签一摘就再也够不到这个人了
function ybih:room/ttt_abort

tag @s remove ybih_player
scoreboard players set @s ybih.id 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0
