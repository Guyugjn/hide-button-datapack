# ybih:game/enter_searching_classic —— 经典模式：全员回集合点开始搜寻
#
# 只有一个人时场上没有「别人的按钮」可按，自己的按钮按了也不计数，
# #button_count 永远归不了零，只能干等 #search_time 跑完（默认 600 秒）。
# 这种情况下直接跳过搜寻进入结算。
#
# 判据用「场上按钮数」而不是「在线人数」：人数会在藏匿途中因为掉线而减少，
# 2 人开局、1 人掉线时线上只剩 1 人，可是场上还有一个别人藏的按钮等着被按，
# 按人数判会把这个阶段整个跳掉，把该得的分吞了。
# 按钮数才真正对应「搜寻阶段有没有事可做」

tag @a remove ybih_current
execute if entity @e[tag=ybih_center] as @a[tag=ybih_player] run tp @s @e[tag=ybih_center,limit=1]

# 场上不足 2 个按钮 → 没有「别人的按钮」可找，跳过搜寻
execute if score #button_count ybih.config matches ..1 run function ybih:game/end_round
execute if score #button_count ybih.config matches 2.. run title @a title {{TXT_S}}开始搜寻{{TXT_M}}gold{{TXT_E}}
execute if score #button_count ybih.config matches 2.. run title @a subtitle {{TXT_S}}去按下别人的按钮{{TXT_E}}
execute if score #button_count ybih.config matches 2.. run tellraw @a [{{TXT_S}}场上共有 {{TXT_E}},{{SCORE_BUTTONS}},{{TXT_S}} 个按钮{{TXT_E}}]
