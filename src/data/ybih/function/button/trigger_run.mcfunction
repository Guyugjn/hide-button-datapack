# ybih:button/trigger_run —— 聊天栏点击入口：读完值立刻清零
# 藏匿阶段（#state 2）受理三类点击：按钮的确认 1 / 取消重放 2，等待室九宫格棋 11..52

execute unless score #state ybih.config matches 2 run scoreboard players set @s ybih.trigger 0
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 1 run function ybih:button/confirm_do
execute if score #state ybih.config matches 2 if score @s ybih.trigger matches 2 run function ybih:button/redo_do

# 棋桌只在等待室里生效。手里的棋子书与聊天栏的入口都是过了这一秒还在的东西，
# 而轮到自己藏匿时人已经被拎出房间 —— 不挡住，旧入口就会让人隔空落子。
# 先归零再置位：房间标记万一不在（还没建好、已被拆掉），#t_in 只会是 0
scoreboard players set #t_in ybih.ttt 0
execute at @e[tag=ybih_room,limit=1] if entity @s[distance=..12] run scoreboard players set #t_in ybih.ttt 1

# 11 刷新名单（顺带补名单位、重贴状态）／12 离座／13 只看棋盘
# 13 与 11 分开：11 会连名单一起重贴（话多），只想把棋盘找回来时用 13
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 11 run function ybih:room/ttt_refresh
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 12 run function ybih:room/ttt_leave
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 13 run function ybih:room/ttt_show
# 29 同意／30 拒绝／31 取消自己发出的邀请／32 再来一局
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 29 run function ybih:room/ttt_accept
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 30 run function ybih:room/ttt_decline
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 31 run function ybih:room/ttt_cancel
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 32 run function ybih:room/ttt_again
# 41..52 邀请名单上第 1..12 位
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 41..52 run function ybih:room/ttt_invite

# 20..28 是棋盘上的九个格子。棋盘跟着人走，所以只需要这一份文件：
# 没在房里、没在对局里、没轮到自己，条件自然不成立
execute if score #t_in ybih.ttt matches 1 if score @s ybih.trigger matches 20..28 run function ybih:room/ttt_click

# 人不在房里：手里那本棋子书是跨局留着的，轮到自己藏匿时它照样能翻、照样能点。
# 一句话说清为什么不生效，比默默吞掉点击好
execute if score #state ybih.config matches 2 if score #t_in ybih.ttt matches 0 if score @s ybih.trigger matches 11..52 run tellraw @s {{TXT_S}}棋桌在等待室里，轮到你藏的时候再去下{{TXT_M}}gray{{TXT_E}}
scoreboard players set @s ybih.trigger 0
# 点击通道每用一次就被系统关掉，这里重新开口，人才能接着落子
scoreboard players enable @s ybih.trigger
