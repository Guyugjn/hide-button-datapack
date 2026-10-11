# ybih:button/award_dec —— 按钮分值递减一份，拿完就收掉它
# 执行者是按下者，被取分的按钮由 ybih_active 标出
#
# #gained 是「这次拿到的分」，计分要用它，所以递减后的余额另记一个变量，不要覆盖它。
# 余额为 0 说明这个按钮的分已经全部被取走
#
# 「还剩几分 / 分被拿完」这两句原先只发给按下者，现在由 button/press_broadcast
# 统一播报（它同时告诉全场谁拿走了几分），所以这里不再重复发私聊

scoreboard players remove @e[tag=ybih_active,limit=1] ybih.value 1
scoreboard players operation #btn_left ybih.config = @e[tag=ybih_active,limit=1] ybih.value
execute if score #btn_left ybih.config matches ..0 run function ybih:button/consume
# 轮流模式一轮只有一个按钮，它的分被拿完就等于每位搜寻者都取过一份，可以收官。
# 经典模式按约定只走搜寻倒计时，这里不结束
execute if score #mode ybih.config matches 2 if score #btn_left ybih.config matches ..0 run function ybih:game/end_round
