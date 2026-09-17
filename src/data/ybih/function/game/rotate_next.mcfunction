# ybih:game/rotate_next —— 轮流模式：决定下一位藏匿者，或收官
# 判据是「谁还没藏过」，不看开局时算死的人数
# 先判定再执行：判定结果记在 #more 里，避免后面的函数改动状态后再被重新判一次

scoreboard players set #more ybih.config 0
execute unless entity @a[tag=ybih_player] run scoreboard players set #more ybih.config -1
execute if score #more ybih.config matches 0 if entity @a[tag=ybih_player,scores={ybih.turn=0}] run scoreboard players set #more ybih.config 1
execute if score #more ybih.config matches 0 if score #cycle ybih.config < #rounds ybih.config run scoreboard players set #more ybih.config 2
execute if score #more ybih.config matches 1 run function ybih:game/next_round
execute if score #more ybih.config matches 2 run function ybih:game/cycle_next
execute if score #more ybih.config matches ..0 run function ybih:game/final_summary
