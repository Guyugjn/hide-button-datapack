# ybih:button/press_broadcast —— 全局播报这一次按下（执行者是按下者）
#
# 播报内容：谁从谁的按钮上取走了几分、那个按钮还剩几分。
# 这是「看得出局势」的主要来源 —— 在此之前按下只给按下者一行私聊，
# 其余人不知道场上发生了什么，也感受不到互相追赶。
#
# **物主的名字只能在他自己的上下文里渲染出来**（选择器组件的 @s 渲染的是执行者的名字），
# 所以主版本放到物主身上发；而按下者的名字反过来用临时标记 ybih_presser 选回来 ——
# 选择器组件接受任意实体选择器，@e[tag=…] 会渲染成那个实体的名字。
# 两边的名字这样才都拿得到。
#
# 物主此刻不在线就退回不带物主名字的版本（@a 选不中离线玩家，
# 与 showcase_bar 处理「物主离线」同一套分支写法）。
# 没有这条兜底的话，物主一掉线，这一次按下的播报会**整条消失**
#
# #btn_remain 是「这次取走后还剩几份」，由 award_score 在调进来之前算好：
# award_dec 里的递减排在后面，这里还读不到递减后的值

tag @s add ybih_presser
scoreboard players set #press_live ybih.config 0
execute as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run scoreboard players set #press_live ybih.config 1
execute if score #press_live ybih.config matches 1 as @a[tag=ybih_player] if score @s ybih.id = #press_owner ybih.config run function ybih:button/press_broadcast_owner
execute if score #press_live ybih.config matches 0 if score #btn_remain ybih.config matches 1.. run tellraw @a [{{SEL_S}}@e[tag=ybih_presser,limit=1]{{SEL_E}},{{TXT_S}} 取走 {{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分 · 那个按钮还剩 {{TXT_E}},{{SCORE_BTNREMAIN}},{{TXT_S}} 分{{TXT_M}}gold{{TXT_E}}]
execute if score #press_live ybih.config matches 0 if score #btn_remain ybih.config matches ..0 run tellraw @a [{{SEL_S}}@e[tag=ybih_presser,limit=1]{{SEL_E}},{{TXT_S}} 取走 {{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分 · 那个按钮的分被拿完了{{TXT_M}}gold{{TXT_E}}]
tag @s remove ybih_presser
