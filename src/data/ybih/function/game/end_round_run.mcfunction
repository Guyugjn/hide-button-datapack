# ybih:game/end_round_run —— 本轮结束：保底结算、播报，然后交给围观或直接收尾
#
# 保底分必须排在 ranking 之前：名次榜播的是结算完的分数，
# 排在后面就会播到加保底分之前的旧值，榜与聊天栏对不上

function ybih:game/bonus_settle
function ybih:game/ranking
function ybih:game/showcase_begin
