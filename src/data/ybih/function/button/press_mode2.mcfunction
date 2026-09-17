# ybih:button/press_mode2 —— 轮流模式：按钮不消失，记录每位搜寻者找到的先后
# 归属判定与经典模式一致：进度记下的按钮编号要与被按下的这个按钮对得上

tag @s add ybih_pressed
tag @e[tag=ybih_active] remove ybih_active
tag @s add ybih_active
scoreboard players operation #press_owner ybih.config = @s ybih.owner_id
scoreboard players operation #press_bid ybih.config = @s ybih.bid

tag @a remove ybih_user
scoreboard players operation #use_min ybih.config = #tick ybih.config
scoreboard players remove #use_min ybih.config 2
execute as @a[tag=ybih_player,scores={ybih.found=0,ybih.used=1..}] if score @s ybih.used >= #use_min ybih.config if score @s ybih.used_bid = #press_bid ybih.config run tag @s add ybih_user

execute as @a[tag=ybih_user,scores={ybih.found=0}] run function ybih:button/found_one

tag @a remove ybih_user
