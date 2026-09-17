# ybih:game/cycle_next —— 轮流模式：一个周期轮完，开下一个周期
# 周期 = 每个参与者各藏一次；是否该开新周期由 rotate_next 判定

scoreboard players add #cycle ybih.config 1
scoreboard players set @a[tag=ybih_player] ybih.turn 0
tellraw @a [{{TXT_S}}第 {{TXT_E}},{{SCORE_CYCLE}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDS}},{{TXT_S}} 个周期开始，回合重新轮一遍{{TXT_M}}gold{{TXT_E}}]
function ybih:game/next_round
