# ybih:player/apply_buff —— 对局保险：抗性提升到顶，饥饿、摔落、怪物伤害一并免掉
# 抗性免不掉「被边界挡在外面」这件事，边界本身是物理屏障；虚空伤害也照样会死
# 抗性也不减免饥饿伤害，所以饱和要一起给：饱和 V 每 tick 补满饥饿，两条合起来才真正不掉血

effect give @s minecraft:resistance 999999 4 true
effect give @s minecraft:saturation 999999 4 true
tag @s add ybih_buffed
