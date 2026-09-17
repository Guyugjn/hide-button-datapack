# ybih:game/turn_timeout_mode2 —— 轮流模式：本轮没藏成，跳过搜寻直接结算

scoreboard players set #seekers_left ybih.config 0
function ybih:game/end_round_run
