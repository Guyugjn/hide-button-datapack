# ybih:game/turn_next —— 选出下一位藏匿者并准备场地

tag @a remove ybih_current
scoreboard players set #best ybih.config 0
execute as @a[tag=ybih_player,scores={ybih.turn=0}] run function ybih:turn/pick_best
execute as @a[tag=ybih_player,scores={ybih.turn=0}] run function ybih:turn/mark_current
# 此刻藏匿者还在线，先把他的编号记下来：万一他中途掉线，
# 超时结算就只能靠这个编号去找人（@a 选不中离线玩家）
scoreboard players set #hide_id ybih.config 0
scoreboard players operation #hide_id ybih.config = @a[tag=ybih_current,limit=1] ybih.id
execute if entity @a[tag=ybih_current] run scoreboard players operation #hide_timer ybih.config = #hide_time ybih.config
execute if entity @a[tag=ybih_current] run scoreboard players set #actionbar_timer ybih.config 20
execute as @a[tag=ybih_current] run function ybih:player/give_buttons
execute if entity @a[tag=ybih_current] run function ybih:turn/gather
execute unless entity @a[tag=ybih_current] run function ybih:game/enter_searching

# 换人由玩家确认触发，不经过每秒循环，这里补刷一次，免得进度条停在上一个人
function ybih:game/bar_update
