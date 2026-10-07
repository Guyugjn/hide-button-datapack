# ybih:room/info_one —— 等待者本人：物品栏上方一行，每秒刷新
# 内容：谁在藏、还剩几秒、自己在队列里排第几、手上攒了多少分
# 队列位次靠「还没藏过的人里编号比我小的有几个」数出来，参与者最多十几人，
# 每秒一次可以接受；#my_id 先存下来，进入 as 循环后就取不到外层的 @s 了

scoreboard players operation #my_id ybih.config = @s ybih.id
scoreboard players set #my_rank ybih.config 1
# 只数「还没藏过、而且不是正在藏的那个人」。正在藏的人此刻 ybih.turn 仍是 0
# （确认那一刻才置 1），不排掉他，他编号比等待者小时位次就会凭空多一位
execute as @a[tag=ybih_player,tag=!ybih_current,scores={ybih.turn=0}] if score @s ybih.id < #my_id ybih.config run scoreboard players add #my_rank ybih.config 1

title @s actionbar [{{TXT_S}}正在藏匿：{{TXT_E}},{{SEL_S}}@a[tag=ybih_current,limit=1]{{SEL_E}},{{TXT_S}} · 剩 {{TXT_E}},{{SCORE_HIDE}},{{TXT_S}} 秒 · 你是第 {{TXT_E}},{{SCORE_MYRANK}},{{TXT_S}} 位 · 已得 {{TXT_E}},{{SCORE_SELF}},{{TXT_S}} 分{{TXT_E}}]
