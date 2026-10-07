# ybih:room/enter_reopen —— 已经在房里的人：只重开点击通道，不重复发送门提示
# 与 room/enter 的区别是这里不传送、不播提示音：每轮换人都会重开一次通道，
# 走 enter 会把人从座位上拎起来、提示刷屏

scoreboard players set @s ybih.trigger 0
scoreboard players enable @s ybih.trigger
