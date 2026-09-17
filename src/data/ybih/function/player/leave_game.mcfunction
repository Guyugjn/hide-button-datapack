# ybih:player/leave_game —— 退出对局身份
# 不撤保险效果：它挂到下一次 /reload 为止，中途退出对局也不该掉

tag @s remove ybih_player
tag @s remove ybih_current
scoreboard players set @s ybih.id 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0
