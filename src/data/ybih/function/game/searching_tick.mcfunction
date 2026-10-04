# ybih:game/searching_tick —— 搜寻阶段
# 收官的判据按模式分派：
#   经典 —— 场上按钮的分都被拿完，等于每位搜寻者都取过一份，当场收官。
#          按钮分值初值 = 参与人数 - 1，正好对应「除物主外人人都能取一份」，
#          所以 #button_count 归零与「全都取完」严格等价，不是「按钮被按过一次」。
#          判据挂在这里而不是 consume 里：give_up 也会让按钮离场，那条路径不经过 consume
#   轮流 —— 全场只有一个按钮，它的分被拿完等于所有搜寻者都到了，
#          由 button/award_dec 当场收官；这里不重复判定

scoreboard players remove #actionbar_timer ybih.config 1
execute if score #actionbar_timer ybih.config matches ..0 run function ybih:game/second_tick
execute if score #mode ybih.config matches 1 if score #button_count ybih.config matches ..0 run function ybih:game/end_round
