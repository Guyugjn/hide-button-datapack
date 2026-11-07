# ybih:game/dynamic_abort —— 所有参与者离线时结束整局

execute if score #state ybih.config matches 3 run function ybih:game/bonus_settle
function ybih:game/cleanup_end
