# ybih:game/bonus_settle —— 藏到底的保底分（幂等闸门）
#
# 规则：轮末结算时，一个**一次都没被按过**的按钮说明没人找到它，物主拿 floor(参与人数 / 2)。
# 这是「藏得好」在计分上的唯一回报 —— 在此之前全库只有「按别人的按钮」一个加分点，
# 藏得越隐蔽自己越亏，理性最优解是随便塞一下就跑去搜。
#
# 幂等闸门：end_round_run 有两条入口，搜寻收官那条带 #state matches 3 守卫，
# 而 turn_timeout_mode2 是直调、绕过守卫的。计分不能建立在「上层只会调一次」这个假设上，
# 所以这里自己判一次 #bonus_done。
#
# #bonus_done 由每一轮开局（start_begin / next_round）归零，**不能挂在 enter_searching_run 上**：
# 轮流模式「本轮没藏成」那条路径整段跳过搜寻直接结算，上一轮置上的 1 会把这一轮的结算整段吃掉。
#
# 调用点必须排在 game/ranking **之前** —— 名次榜播的是结算完的分数，
# 排在后面就会播到加保底分之前的旧值。
execute if score #bonus_done ybih.config matches 0 run function ybih:game/bonus_run
