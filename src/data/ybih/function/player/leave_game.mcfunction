# ybih:player/leave_game —— 退出对局身份
# 不撤保险效果：它挂到下一次 /reload 为止，中途退出对局也不该掉
#
# 这里**不摘** ybih_current：摘了就等于把观战夜视的追索线索掐断 ——
# 所有以它选人的回收点随即失效，效果只能等自己熄灭。
# 凭据与它的夜视由 player/buff_guard 在 #state 之外统一成对收掉

tag @s remove ybih_player
scoreboard players set @s ybih.id 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0
