# ybih:game/bonus_pay —— 给这一个按钮的物主发保底分（执行者是按钮标记）
# 由 game/bonus_run 逐个调进来，调用方已经筛过「从没被找到过、且属于本局」
#
# 物主此刻不在线就整段作废：@a 只遍历在线玩家，够不到离线的人。
# 与项目里其余一次性收尾点同一口径 —— 它们都不把离线玩家当成需要兜底的对象。
# 代价是「藏着按钮时掉线」会失去这份分，但换来的是不必再养一份位图与金额存储
#
# 编号为 0 是「没有编主」而不是一个编号，与 press_begin 里 #press_bid matches 1.. 同一道理：
# 不加这道守卫的话，一个 owner_id 为 0 的标记会把分发给恰好 id 也是 0 的玩家
# （退场的人会被 leave_game 把 ybih.id 清零，所以这种人真实存在）

scoreboard players set #bonus_owner ybih.config 0
scoreboard players operation #bonus_owner ybih.config = @s ybih.owner_id
scoreboard players set #bonus_got ybih.config 0
# 先记「这个按钮没被找到」——它和「物主拿到了分」是两件事：
# 物主不在线时这个按钮照样算没被找到，但下面三条一条都不会命中
scoreboard players add #bonus_total ybih.config 1
execute if score #bonus_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.id = #bonus_owner ybih.config run scoreboard players set #bonus_got ybih.config 1
execute if score #bonus_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.id = #bonus_owner ybih.config run scoreboard players operation @s ybih.score += #bonus_amt ybih.config
execute if score #bonus_owner ybih.config matches 1.. as @a[tag=ybih_player] if score @s ybih.id = #bonus_owner ybih.config run tellraw @s [{{TXT_S}}你的按钮一次都没被找到，保底 +{{TXT_E}},{{SCORE_BONUS_AMT}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #bonus_got ybih.config matches 1 run scoreboard players add #bonus_count ybih.config 1
