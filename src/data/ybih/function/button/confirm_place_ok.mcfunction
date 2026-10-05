# ybih:button/confirm_place_ok —— 确认藏匿：计数、清空其余按钮、推进回合

# 此刻藏匿者就站在按钮旁，区块必然加载，是钉住它唯一可靠的时机。
# 没被按到的按钮不会再经过 button/consume，到轮末人早被传回集合点、
# 区块随之卸载，showcase_begin 的 @e 就数不到它，那一个会被静默漏展示。
# 打上 ybih_pinned 作为「这个标记申请过区块强加载」的凭据：四条清理路径
# 都靠它 forceload remove，标记被 kill 之前先释放，不会漏掉任何一次申请
# 必须排在摘掉 ybih_pending 之前：摘完这个选择器就选不中它了
execute as @e[tag=ybih_pending] at @s run forceload add ~ ~
tag @e[tag=ybih_pending] add ybih_pinned
# 这个按钮能吃几份分：除物主以外的人都可能来按，所以份数 = 参与者总数 - 1。
# 分值挂在按钮自己身上（ybih.value），场上每个按钮各算各的，互不影响。
# 物主自己按不给分，所以这个数字正好等于能从这个按钮上拿分的次数。
# 这一段必须排在摘掉 ybih_pending 之前 —— 那是本回合唯一能选中这个按钮的标签
scoreboard players operation @e[tag=ybih_pending] ybih.value = #player_count ybih.config
scoreboard players remove @e[tag=ybih_pending] ybih.value 1
scoreboard players set @e[tag=ybih_pending] ybih.hit 0
tag @e[tag=ybih_pending] remove ybih_pending
scoreboard players add #button_count ybih.config 1
scoreboard players set @s ybih.placed 1
scoreboard players set @s ybih.turn 1
clear @s #minecraft:buttons
playsound minecraft:block.stone_button.click_on player @s ~ ~ ~ 1 1.2
tellraw @a [{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 已藏好按钮{{TXT_M}}green{{TXT_E}}]
function ybih:game/turn_advance
