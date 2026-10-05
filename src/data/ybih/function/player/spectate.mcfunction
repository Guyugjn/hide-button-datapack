# ybih:player/spectate —— 转为旁观：记下原模式、发一份带凭据的观战夜视、传送到中心点
# 只由 player/active_state:11 调用，执行者一定是「当前不是旁观」的在线非参赛者：
# 服主自己 /gamemode spectator 的观战身份走不到这里，程序不接管它，也不改写它 ——
# 那份身份原样留到对局结束，收尾点没有他的记录，也不替他做决定
#
# 原模式必须在这里记：这一刻他还没被切成旁观，记下的才是真实模式。
# 收尾点（game/showcase_end 与三个收尾点）按记录还原之后，game/next_round
# 就能照设计把「非旁观且非参赛者」的他并入下一局。不记的话他会一直停在旁观，
# 而旁观模式不能自己执行 /gamemode（管理员可以用命令，普通玩家下不了场），等于再也下不了场
#
# 夜视的凭据是 ybih_spect_nv，不变量是「有凭据 = 当前在旁观」：
# 人在旁观，player/buff_guard 每秒顶上，一直是亮的；凭据被回收、或人不再是旁观，
# 最迟一秒后连效果一起收掉。时长取 60 秒 —— 刷新周期的 60 倍，留足余量；
# 万一凭据没了又没人回收，最多一分钟自己熄灭，不会像 999999 那样在存档里
# 陪着人跨局、跨 reload、跨重连一直挂着

tag @s remove ybih_gm_survival
tag @s remove ybih_gm_creative
tag @s remove ybih_gm_adventure
execute if entity @s[gamemode=survival] run tag @s add ybih_gm_survival
execute if entity @s[gamemode=creative] run tag @s add ybih_gm_creative
execute if entity @s[gamemode=adventure] run tag @s add ybih_gm_adventure

gamemode spectator @s
effect give @s minecraft:night_vision 60 0 true
tag @s add ybih_spect_nv
execute if entity @e[tag=ybih_center] run tp @s @e[tag=ybih_center,limit=1]
tellraw @s {{TXT_S}}你以旁观身份观看本局{{TXT_M}}gray{{TXT_E}}
