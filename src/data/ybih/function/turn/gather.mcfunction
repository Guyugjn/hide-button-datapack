# ybih:turn/gather —— 藏匿者回到中心点，其余参与者送进高空等待室

execute if entity @e[tag=ybih_center] as @a[tag=ybih_current] run tp @s @e[tag=ybih_center,limit=1]
# 被拎出去藏按钮的人手里的棋局当场作废。
# 每秒的巡检（room/ttt_tick）本来也能发现他不在房里，但那要等下一秒，
# 对手会白等一秒才看到「对手走了」；这里立刻结清，残局也立刻清干净。
# 只对还挂着局面的人调：空闲的人走这一趟只会白收一句「你退出了这一局」
execute as @a[tag=ybih_current,scores={ybih.tstate=1..}] run function ybih:room/ttt_abort
# 名单位也交回去：他这一轮都在场上，不该再占着名单上的位子。
# 交回走 room/ttt_release —— 占用表（#rsN）与本人的 rseat 必须成对清，
# 只清 rseat 会让那个位子被永久占住
execute as @a[tag=ybih_current,scores={ybih.rseat=1..}] run function ybih:room/ttt_release
# 先确认等待室地板真的砌好了再送人，避免万一没建成把人从高空放下去。
# 地板是浅灰地毯（见 util/build_wait_room），换地板材质必须同步改这一行。
# 两条按「人现在离房间多远」分工：外面的人走 room/enter（落位 + 进门提示），
# 已经在房里的人只重开点击通道 —— 每轮换人都会走到这里，
# 对里面的人重发一遍进门提示与棋子书就成了刷屏
execute at @e[tag=ybih_room,limit=1] if block ~ ~ ~ minecraft:light_gray_carpet as @a[tag=ybih_player,tag=!ybih_current,distance=13..] run function ybih:room/enter
execute at @e[tag=ybih_room,limit=1] if block ~ ~ ~ minecraft:light_gray_carpet as @a[tag=ybih_player,tag=!ybih_current,distance=..12] run function ybih:room/enter_reopen
title @a[tag=ybih_current] title {{TXT_S}}轮到你了{{TXT_M}}gold{{TXT_E}}
title @a[tag=ybih_current] subtitle {{TXT_S}}藏好你的按钮{{TXT_E}}
tellraw @a[tag=ybih_player,tag=!ybih_current] {{TXT_S}}有人在藏按钮，请稍候{{TXT_M}}gray{{TXT_E}}
