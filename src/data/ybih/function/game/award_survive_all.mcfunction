# ybih:game/award_survive_all —— 本轮结束时，按钮还留在场上的人各 +1 分

execute as @a[tag=ybih_player,scores={ybih.placed=1}] run function ybih:game/award_survive
