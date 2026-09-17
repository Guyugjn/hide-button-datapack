# ybih:game/end_round_run —— 本轮结束：结算、播报，然后交给围观或直接收尾

execute if score #mode ybih.config matches 1 run function ybih:game/award_survive_all
execute if score #mode ybih.config matches 2 run function ybih:game/award_hider
function ybih:game/ranking
function ybih:game/showcase_begin
