# ybih:player/rejoin —— 重连玩家恢复参与身份
# 轮流模式的搜寻阶段中途回来，本轮不参与抢按，避免打乱找到顺序
#
# 掉线期间若正好轮到他藏，超时结算已经按编号把他的分与 turn 一并处理过了
# （见 game/turn_timeout），这里不必再补 —— 周期号的判据在两个方向上都会出错：
# 周期还没翻过去时修不到他，翻过去了又会把本该轮到他的人误判成已藏过

tag @s add ybih_player
gamemode adventure @s
execute unless score @s ybih.finds matches 0.. run scoreboard players set @s ybih.finds 0
execute unless score @s ybih.t_first matches 0.. run scoreboard players set @s ybih.t_first 999999
execute if score #state ybih.config matches 3 if score #mode ybih.config matches 2 run scoreboard players set @s ybih.found 1
execute unless entity @s[tag=ybih_buffed] run function ybih:player/apply_buff
tellraw @s {{TXT_S}}欢迎回来，你仍在局中{{TXT_M}}green{{TXT_E}}
