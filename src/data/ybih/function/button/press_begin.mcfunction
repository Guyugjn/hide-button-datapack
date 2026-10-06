# ybih:button/press_begin —— 一次按下只处理一回，并认领按下者
# 执行者是按钮标记（press_scan 逐个按钮调进来）
#
# 归属判定：进度「对着按钮交互」记下的按钮编号，必须与被按下的这个按钮对得上
#
# 只判「N tick 内交互过方块」是不够的：交互的可能是旁边的箱子、门或随手挖的一下，
# 窗口内有多人时归属还会随遍历顺序变。所以进度带 location 谓词只放按钮交互进来，
# 再由 on_use 射线锁定是哪一个按钮、把编号记进 ybih.used_bid，这里精确对上号
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
execute as @a[tag=ybih_player,scores={ybih.used=1..}] if score @s ybih.used >= #use_min ybih.config if score @s ybih.used_bid = #press_bid ybih.config run tag @s add ybih_user

execute if entity @a[tag=ybih_user] as @a[tag=ybih_user,limit=1,sort=nearest] run function ybih:button/press_claim

# 自检之「射线没锁到按钮」：进度已经确认有人对着按钮交互过（ybih.used 落在时间窗内），
# 却没有一个人的 ybih.used_bid 被写上（仍是 0）—— 说明 on_use_trace 跑了，但射线
# 一个本局按钮标记都没探到，归属比对必然落空，这次按下不计分、也没有任何提示。
# 只在「确实有人交互过、且没人被认领」时触发，所以纯红石/箭矢打亮的按钮不会误报
execute if entity @a[tag=ybih_player,scores={ybih.used=1..}] unless entity @a[tag=ybih_user] as @a[tag=ybih_player,scores={ybih.used=1..,ybih.used_bid=0},limit=1,sort=nearest] if score @s ybih.used >= #use_min ybih.config run tellraw @s {{TXT_S}}这次按下没算数：没能在视线方向上锁定到按钮标记，请把按钮放在更容易点到的位置，或检查它是否已被拿完{{TXT_M}}red{{TXT_E}}

tag @a remove ybih_user
