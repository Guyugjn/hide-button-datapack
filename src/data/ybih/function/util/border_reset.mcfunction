# ybih:util/border_reset —— 把世界边界恢复成游戏初始状态
# 边界命令只作用于执行时所在的维度，所以写死主世界
# 读回一次实际直径，供聊天栏与设置书确认生效

execute in minecraft:overworld run worldborder set 59999968
execute in minecraft:overworld run worldborder center 0 0
execute in minecraft:overworld store result score #bw_now ybih.config run worldborder get
