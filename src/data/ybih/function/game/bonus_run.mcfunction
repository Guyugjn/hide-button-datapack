# ybih:game/bonus_run —— 保底分结算本体（只由 bonus_settle 的闸门调进来）
#
# 为什么用 ybih.hit 判「从没被找到」：
#   · ybih.value 只说明「还剩几份分」，被按过一次的按钮 value 仍大于 0，两种情形分不开
#   · 这里是**全零判定**（有没有任何一位被置过），不是「某一位是否置过」，
#     所以不受 award_grant 那套按位取模的编号顺序影响 —— 那里用 #hit_now == 0
#     判「没人按过」是错的（先按的人编号更大时 16 % 4 == 0，会误判成没人按过）
#
# 被找到过哪怕一次就不给：那时它的价值已经由按下那一刻结清了，剩下的分照旧作废。
# 复用 #player_count 而不是现数在线人数：它是本轮开局定下来的参与者总数，
# 与 confirm_place_ok 给按钮定值的口径同源，中途掉线的人不会让保底分缩水
#
# 物主此刻不在线就跳过（见 bonus_pay）：一次性收尾点都够不到离线玩家，
# 这是项目里既有的口径，不在这里另起一套补还机制

scoreboard players set #bonus_done ybih.config 1
scoreboard players set #bonus_count ybih.config 0
scoreboard players set #bonus_total ybih.config 0
scoreboard players operation #bonus_amt ybih.config = #player_count ybih.config
scoreboard players operation #bonus_amt ybih.config /= #c2 ybih.config

# 一人的局保底分是 0（1 / 2 向下取整），整段跳过，免得播一句「各得 0 分」
execute if score #bonus_amt ybih.config matches 1.. as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending,scores={ybih.hit=0}] if score @s ybih.era = #era ybih.config run function ybih:game/bonus_pay

# 播报要点：**「几个按钮没被找到」与「几位物主拿到了分」是两个数**。
# 物主不在线时那个按钮照样算没被找到，但他拿不到分；混用一个数会报出
# 「有 2 个按钮一次都没被找到，物主各得 3 分」—— 实际上只有一位物主拿到了。
# 两个数相等（都发成功了）时用短句，不等时点明差额，让人知道有人没在线
execute if score #bonus_total ybih.config matches 1.. if score #bonus_total ybih.config = #bonus_count ybih.config run tellraw @a [{{TXT_S}}有 {{TXT_E}},{{SCORE_BONUS_TOTAL}},{{TXT_S}} 个按钮一次都没被找到，物主各得 {{TXT_E}},{{SCORE_BONUS_AMT}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #bonus_total ybih.config matches 1.. unless score #bonus_total ybih.config = #bonus_count ybih.config run tellraw @a [{{TXT_S}}有 {{TXT_E}},{{SCORE_BONUS_TOTAL}},{{TXT_S}} 个按钮一次都没被找到，其中 {{TXT_E}},{{SCORE_BONUS_COUNT}},{{TXT_S}} 位物主各得 {{TXT_E}},{{SCORE_BONUS_AMT}},{{TXT_S}} 分（其余物主不在线，不发）{{TXT_M}}gold{{TXT_E}}]
