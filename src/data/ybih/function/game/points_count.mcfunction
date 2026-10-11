# ybih:game/points_count —— 数出「场上还剩多少分」与「几个按钮一次都没被找到」
#
# 一次遍历同时得两个量，都是给玩家看的局势信息：
#   #points_left   场上还没被取走的分总和 —— 搜寻期 Boss 栏常驻显示，
#                  每次按下都会当场变小，玩家能看着它掉
#   #unfound_count 一次都没被按过的按钮数 —— 保底窗口还开着的那些，
#                  它降到 0 就是「所有按钮都被找到了」这个转折点
# 两个量都由 game/points_tally 在这同一次 as @e 里数出来
#
# 每次现算，不做增量维护：增量需要在 confirm_place_ok / award_dec / give_up
# 三处同步加减，是典型的出错源（项目里已经有过「两处减法都要带 0 下界」这类教训）。
# 成本口径：只在搜寻阶段每秒一次、只遍历按钮标记，与既有的 hint_scan 同一量级；
# press_tick 每 tick 的那次遍历不受影响。改这里时留意别把它挪进每 tick 的路径
#
# 只算本局的：往局残留在未加载区块里的标记带着 ybih_button，靠 #era 隔开
# 待确认的不算（还没登记为对局按钮，value 还没写，-era 也可能还没落上）

scoreboard players set #points_left ybih.config 0
scoreboard players set #unfound_count ybih.config 0
execute as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config run function ybih:game/points_tally

# 保底窗口刚刚关上：由「还有没人找到的按钮」变成「一个都没有了」。
# 用 #unfound_prev 记上一秒的值来抓这个转折，而不是用 unfound_count == 0 直接判 ——
# 后者在搜寻期每一秒都会成立，会变成一个每秒重复一次的刷屏
execute if score #unfound_prev ybih.config matches 1.. if score #unfound_count ybih.config matches 0 run tellraw @a {{TXT_S}}所有按钮都已被找到，藏到底的保底分全部作废{{TXT_M}}gray{{TXT_E}}
scoreboard players operation #unfound_prev ybih.config = #unfound_count ybih.config
