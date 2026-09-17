# ybih:game/ranking —— 播报本轮结束与当前最高分

tellraw @a [{{TXT_S}}—— 第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} 轮结束 ——{{TXT_M}}gold{{TXT_E}}]
function ybih:game/rank_broadcast
