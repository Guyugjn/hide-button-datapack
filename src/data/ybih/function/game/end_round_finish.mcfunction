# ybih:game/end_round_finish —— 本轮收尾：清场，然后续轮或收官
# 围观结束后才走到这里，判定放在 classic_next / rotate_next 里做

function ybih:game/cleanup_buttons
execute if score #mode ybih.config matches 1 run function ybih:game/classic_next
execute if score #mode ybih.config matches 2 run function ybih:game/rotate_next
