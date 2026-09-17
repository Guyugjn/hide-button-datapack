# ybih:button/use_lock —— 射线命中一个按钮标记：把它的编号抄给射线发起玩家
# 执行者是射线发起玩家，编号从标记身上读，所以用 execute as 切到标记取一次值
#
# 只认本局的按钮（ybih.era 与当前局号相符）：往局残留在未加载区块里的标记
# 也带着 ybih_button，抄到它的旧编号会让 press_scan 那边比对不上，这次按下就白按了。
# 命中却读不到编号时（往局残留）不锁定，让射线继续往里找

scoreboard players set #use_bid ybih.config 0
execute as @e[tag=ybih_button,tag=!ybih_pending,distance=..0.8,limit=1,sort=nearest] if score @s ybih.era = #era ybih.config run scoreboard players operation #use_bid ybih.config = @s ybih.bid
execute if score #use_bid ybih.config matches 1.. run tag @s add ybih_ray_found
execute if score #use_bid ybih.config matches 1.. run scoreboard players operation @s ybih.used_bid = #use_bid ybih.config
