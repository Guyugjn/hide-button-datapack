# ybih:game/end_round —— 结算入口（仅搜寻阶段有效，避免重复触发）

execute if score #state ybih.config matches 3 run function ybih:game/end_round_run
