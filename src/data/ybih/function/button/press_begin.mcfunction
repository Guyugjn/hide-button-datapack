# ybih:button/press_begin —— 一次按下只处理一回，并认领按下者
# 执行者是按钮标记（press_scan 逐个按钮调进来），位置也停在按钮标记上
#
# 归属判定先数一数时间窗内（#use_min..#tick）有几个本局玩家交互过按钮：
#
#   编号直接对上 —— 无论窗口内有几个人，这就是最可靠的证据，直接认领
#   只有一个交互者 —— 按下的就是他，不再要求编号对上号（见下）
#   两个以上、编号又对不上 —— 这次按下不算数
#
# 为什么唯一候选那一档要放宽编号比对：按下定位射线的采样点是按整格取的
# （button/use_probe 先 align xyz 再取格心），而按钮的可点区域（判定箱）只有
# 6/16 格宽 × 2/16 格厚、并不铺满整格。按钮挨着摆时（同一面墙左右相邻、
# 地上前后一排、同列上下叠放），斜着看过去射线可能先进入前面那个按钮的格子，
# 于是 ybih.used_bid 记成了前面那个编号，与 #press_bid 对不上 ——
# 原来的判定直接落空，这次按下不计分、聊天栏一个字都没有，
# 玩家看到的是「按钮有动画有音效，但按了没反应」。只有一个候选时不存在认错人的可能，
# 所以不必靠编号来分人
#
# 放宽是「多给一次机会」，不是「无条件认领」，所以另有两道闸门把关：
#   #mismatch —— 锁到的编号既不是本按钮、也不在本按钮 1.5 格内，说明锁到了别处（见下）
#   #lock_lit —— 锁到的那个按钮自己正被按下，说明那才是真正被按的按钮，
#                本按钮只是同时被别的东西点亮。若不加这道闸门，
#                有人按下 A 的同时旁边 B 被箭打亮，B 也会跟着给分
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

# 时间窗内有几个本局玩家交互过按钮。距离上限与下面两条认领路径保持一致 ——
# 数进来的人必须是「有可能按下这个按钮的人」：隔着半张地图的人不可能按到它，
# 却会把 #cand 顶到 2、把「唯一候选者」那一档整段关掉，于是并排按钮的原始缺陷
# 在多人同时各自按按钮时照样丢分。计数与认领的口径必须一致，否则放宽形同虚设
scoreboard players set #cand ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config run scoreboard players add #cand ybih.config 1

# 唯一候选者锁到的那个按钮编号（#cand 为 1 时就是他那一个）
scoreboard players set #lock_bid ybih.config 0
execute if score #cand ybih.config matches 1 as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config run scoreboard players operation #lock_bid ybih.config = @s ybih.used_bid

# 锁到的那个按钮在不在本按钮旁边。这行停在按钮标记上量距离，
# 不能并进下面那几行 —— 那几行已经 as 到玩家身上，原点会变成玩家的位置。
# at @s 是显式写出来的：调用链（press_tick → press_scan → on_press → press_begin）
# 一路都用 at @s 把位置带过来，这里再钉一次，免得日后有人改了上游就悄悄量错。
#
# 上限取 1.8，覆盖到**体对角线**：射线采样点是按格走的，落错时最多在三个轴上各偏一格，
# 两个标记格心最远相距 √3 ≈ 1.732（面对角线只有 1.414，按那个数写会漏掉斜向错开一格的摆法）
scoreboard players set #near_ok ybih.config 0
execute if score #lock_bid ybih.config matches 1.. at @s as @e[tag=ybih_button,tag=!ybih_pending,distance=..1.8] if score @s ybih.era = #era ybih.config if score @s ybih.bid = #lock_bid ybih.config run scoreboard players set #near_ok ybih.config 1

# 锁到的那个按钮自己是不是正被按下（它自己的方块在 powered 状态）。
# 这道判定用来分开两种情况：
#   射线落错格子 —— 锁到的是被动按下的那个按钮的**邻居**，邻居自己没有亮 → 不亮
#   这个按钮是被箭打亮的、而锁到的是真正被按下的那个按钮 —— 那个按钮自己亮着 → 亮
# 后一种绝不能算到本按钮头上，否则一支箭打亮的按钮会跟着旁边那次真实按下一起计分。
# 这一行与上一行的原点不同：上一行要「离被按按钮多远」（原点在按钮标记上），
# 这一行要「那个按钮自己的方块状态」（原点在它自己身上），所以必须分成两行
scoreboard players set #lock_lit ybih.config 0
execute if score #lock_bid ybih.config matches 1.. as @e[tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config if score @s ybih.bid = #lock_bid ybih.config at @s if block ~ ~ ~ #minecraft:buttons[powered=true] run scoreboard players set #lock_lit ybih.config 1

# 锁到了「别处那个按钮」：有编号、不是本按钮、也不在本按钮旁边。
# 这种锁定结果不能用来认领，唯一候选那一档要排除掉
scoreboard players set #mismatch ybih.config 0
execute if score #lock_bid ybih.config matches 1.. unless score #lock_bid ybih.config = #press_bid ybih.config if score #near_ok ybih.config matches 0 run scoreboard players set #mismatch ybih.config 1

# 一、编号直接对上 —— 无论窗口内有几个人，这就是最可靠的证据。
# 带 #press_bid matches 1.. ：编号 0 是「没有编号」而不是一个编号，不加这道守卫的话
# 只要出现一个编号为 0 的按钮标记，任何没锁到东西的人（used_bid 也是 0）都会被判成
# 「编号正好对上」而白拿一份分。另外几处比编号的地方都带了同样的守卫，这里不能漏
execute if score #press_bid ybih.config matches 1.. as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config if score @s ybih.used_bid = #press_bid ybih.config run tag @s add ybih_user
# 二、唯一候选者，且锁定结果可信（没锁到「别处那个按钮」、锁到的按钮自己也没在被按）—— 按下的就是他
execute if score #cand ybih.config matches 1 if score #mismatch ybih.config matches 0 if score #lock_lit ybih.config matches 0 as @a[tag=ybih_player,scores={ybih.used=1..},distance=..8] if score @s ybih.used >= #use_min ybih.config run tag @s add ybih_user

execute if entity @a[tag=ybih_user] as @a[tag=ybih_user,limit=1,sort=nearest] run function ybih:button/press_claim

# 自检之「射线没锁到按钮」：进度已经确认有人对着按钮交互过（ybih.used 落在时间窗内），
# 却没有一个人的 ybih.used_bid 被写上（仍是 0）—— 说明 on_use_trace 跑了，但射线
# 一个本局按钮标记都没探到。只在确实有人交互过、且没人被认领时触发，
# 所以纯箭矢 / 三叉戟 / 风弹打亮的按钮不会误报
execute if entity @a[tag=ybih_player,scores={ybih.used=1..}] unless entity @a[tag=ybih_user] as @a[tag=ybih_player,scores={ybih.used=1..,ybih.used_bid=0},limit=1,sort=nearest] if score @s ybih.used >= #use_min ybih.config run tellraw @s {{TXT_S}}这次按下没算数：没能在视线方向上锁定到按钮标记，请把按钮放在更容易点到的位置，或检查它是否已被拿完{{TXT_M}}red{{TXT_E}}

# 自检之「锁到的是另一个按钮」：射线锁上了编号，但那不是被按下的这个，而这一回又没能靠
# 唯一候选认领（同时有多人在交互，或人都离得远）—— 这次按下同样不计分。
# 与上一条的区别：上一条编号是 0（什么都没锁到），这条编号非 0 但对不上。
# 带 #lock_lit 条件：若锁到的那个按钮自己正被按下，那一份分会记在它自己那次判定上，
# 这次不计分是正确的（一个人只该取走一份），不该再报「没算数」去误导玩家。
#
# 由此留下一个**不再提示**的出口，这里说明白它为什么可以接受：走到「#lock_lit=1 且无人认领」
# 需要同时满足「唯一候选者」「锁到的是另一个按钮」「那个按钮自己正被按下」。而那个按钮自己
# 被按下时，它自己那次 press_begin 也会跑，并且会靠「编号直接对上」把**同一个人**认领走 ——
# 也就是说玩家照样拿到了一份分（金额相同、归属同一个人），只是记在那个按钮头上。
# 既然分没丢，就不该再报「没算数」。反过来，若那个按钮的标记已经被 consume 摘掉
# （分被拿完、转成 ybih_ghost），算 #lock_lit 的那一行带 tag=ybih_button 就选不中它、
# #lock_lit 保持 0，这一条自检照常触发。两个分支都不会出现「白白按下去却什么都没有」。
execute if entity @a[tag=ybih_player,scores={ybih.used=1..}] unless entity @a[tag=ybih_user] if score #lock_lit ybih.config matches 0 as @a[tag=ybih_player,scores={ybih.used=1..,ybih.used_bid=1..},limit=1,sort=nearest] if score @s ybih.used >= #use_min ybih.config run tellraw @s {{TXT_S}}这次按下没算数：视线锁定的按钮和你按下的不是同一个。按钮挨太近时容易这样，把按钮之间隔开一格就能避免{{TXT_M}}red{{TXT_E}}

tag @a remove ybih_user
