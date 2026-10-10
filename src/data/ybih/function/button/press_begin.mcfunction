# ybih:button/press_begin —— 一次按下只处理一回，并认领按下者
# 执行者是按钮标记（press_scan 逐个按钮调进来），位置也停在按钮标记上
#
# 归属判定先数一数时间窗内（#use_min..#tick）有几个本局玩家交互过按钮：
#
#   只有一个 —— 按下的就是他，不再要求编号对上号
#   两个以上 —— 必须编号精确对上号，否则分可能记到旁边的看客头上
#
# 为什么唯一候选那一档要放宽编号比对：按下定位射线的采样点是按整格取的
# （button/use_probe 先 align xyz 再取格心），按钮挨着摆时（同一面墙左右相邻、
# 地上前后一排、同列上下叠放），射线可能先进入前面那个按钮的格子，
# 于是 ybih.used_bid 记成了前面那个编号，与 #press_bid 对不上 ——
# 原来的判定直接落空，这次按下不计分、聊天栏一个字都没有，
# 玩家看到的是「按钮有动画有音效，但按了没反应」。只有一个候选时不存在认错人的可能，
# 所以不必靠编号来分人
#
# 放宽仍有一道闸门：锁上的编号必须「不是别处那个按钮」才算数。
# 「别处」= 那个编号既不是本按钮，也不在本按钮 1.5 格内。
# 相邻摆放的标记最远是面对角线的 1.414 格，所以 1.5 覆盖了各种贴着的摆法；
# 而「有人在别处按了按钮，这个按钮正好被红石或箭矢打亮」时锁到的编号离得很远，
# 不会被误算到那个人头上
#
# 距离上限同理：真按按钮的人一定站在按钮的交互距离内（创造 5 格，量的是脚底到标记，
# 按钮高于脚底时还要多出竖直分量，所以留到 8 格），
# 隔着半张地图的交互不该算到这个按钮头上
#
# 只判「N tick 内交互过方块」仍然不够：交互的可能是旁边的箱子、门或随手挖的一下，
# 所以进度带 location 谓词只放按钮交互进来
#
# 时间窗只用于挡掉陈旧值：玩家很久以前点过这个按钮，
# 又一次被箭打亮时不该把他算成按下者
# 物主同样参与判定，所以自己按自己的按钮只会得到提示，不会把分让给旁边的看客

tag @s add ybih_pressed
tag @e[tag=ybih_active] remove ybih_active
tag @s add ybih_active
scoreboard players operation #press_owner ybih.config = @s ybih.owner_id
scoreboard players operation #press_bid ybih.config = @s ybih.bid

tag @a remove ybih_user
scoreboard players operation #use_min ybih.config = #tick ybih.config
scoreboard players remove #use_min ybih.config 2

# 时间窗内有几个本局玩家交互过按钮
scoreboard players set #cand ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.used=1..}] if score @s ybih.used >= #use_min ybih.config run scoreboard players add #cand ybih.config 1

# 唯一候选者锁到的那个按钮编号（#cand 为 1 时就是他那一个）
scoreboard players set #lock_bid ybih.config 0
execute if score #cand ybih.config matches 1 as @a[tag=ybih_player,scores={ybih.used=1..}] if score @s ybih.used >= #use_min ybih.config run scoreboard players operation #lock_bid ybih.config = @s ybih.used_bid

# 锁到的那个按钮在不在本按钮旁边。这一行必须停在按钮标记上量距离，
# 不能并进下面那几行 —— 那几行已经 as 到玩家身上，原点会变成玩家的位置。
# at @s 是显式写出来的：调用链（press_tick → press_scan → on_press → press_begin）
# 一路都用 at @s 把位置带过来，这里再钉一次，免得日后有人改了上游就悄悄量错
scoreboard players set #near_ok ybih.config 0
execute if score #lock_bid ybih.config matches 1.. at @s as @e[tag=ybih_button,tag=!ybih_pending,distance=..1.5] if score @s ybih.era = #era ybih.config if score @s ybih.bid = #lock_bid ybih.config run scoreboard players set #near_ok ybih.config 1

# 锁到了「别处那个按钮」：有编号、不是本按钮、也不在本按钮旁边。
# 这种锁定结果不能用来认领，唯一候选那一档要排除掉
scoreboard players set #mismatch ybih.config 0
execute if score #lock_bid ybih.config matches 1.. unless score #lock_bid ybih.config = #press_bid ybih.config if score #near_ok ybih.config matches 0 run scoreboard players set #mismatch ybih.config 1

# 一、唯一候选者，且锁定结果不是「别处那个按钮」—— 按下的就是他
execute if score #cand ybih.config matches 1 if score #mismatch ybih.config matches 0 as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config run tag @s add ybih_user
# 二、两个以上候选者 —— 只能靠编号分人，对不上号的这次按下就不算数
execute if score #cand ybih.config matches 2.. as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config if score @s ybih.used_bid = #press_bid ybih.config run tag @s add ybih_user

execute if entity @a[tag=ybih_user] as @a[tag=ybih_user,limit=1,sort=nearest] run function ybih:button/press_claim

# 自检之「射线没锁到按钮」：进度已经确认有人对着按钮交互过（ybih.used 落在时间窗内），
# 却没有一个人的 ybih.used_bid 被写上（仍是 0）—— 说明 on_use_trace 跑了，但射线
# 一个本局按钮标记都没探到。只在确实有人交互过、且没人被认领时触发，
# 所以纯红石 / 箭矢打亮的按钮不会误报
execute if entity @a[tag=ybih_player,scores={ybih.used=1..}] unless entity @a[tag=ybih_user] as @a[tag=ybih_player,scores={ybih.used=1..,ybih.used_bid=0},limit=1,sort=nearest] if score @s ybih.used >= #use_min ybih.config run tellraw @s {{TXT_S}}这次按下没算数：没能在视线方向上锁定到按钮标记，请把按钮放在更容易点到的位置，或检查它是否已被拿完{{TXT_M}}red{{TXT_E}}

# 自检之「锁到的是另一个按钮」：射线锁上了编号，但那不是被按下的这个，而这一回又没能靠
# 唯一候选认领（同时有多人在交互，或人都离得远）—— 这次按下同样不计分。
# 与上一条的区别：上一条编号是 0（什么都没锁到），这条编号非 0 但对不上
execute if entity @a[tag=ybih_player,scores={ybih.used=1..}] unless entity @a[tag=ybih_user] as @a[tag=ybih_player,scores={ybih.used=1..,ybih.used_bid=1..},limit=1,sort=nearest] if score @s ybih.used >= #use_min ybih.config run tellraw @s {{TXT_S}}这次按下没算数：视线锁定的按钮和你按下的不是同一个。按钮挨太近时容易这样，把按钮之间隔开一格就能避免{{TXT_M}}red{{TXT_E}}

tag @a remove ybih_user
