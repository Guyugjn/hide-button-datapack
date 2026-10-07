# ybih:room/rps_fight —— 猜拳结算：定对手那一手、判胜负、连胜断了还是续上
# 对手那一手不掷随机数：/random 是 1.20.2 起才有的，包 1 用不了。
# 改成「每次出拳把 #rps_seed 加一，再和玩家编号相加取模 3」——
# 同一秒里两个人出拳会拿到不同的手，同一个人连着出拳也会换手，够像运气，
# 而且只用记分板运算，三个包都能跑
# 胜负用 (自己的手 - 对手的手 + 3) % 3：0 平、1 赢、2 输

scoreboard players add #rps_seed ybih.config 1
scoreboard players operation #rps_ai ybih.config = #rps_seed ybih.config
scoreboard players operation #rps_ai ybih.config += @s ybih.id
scoreboard players operation #rps_ai ybih.config %= #c3 ybih.config

scoreboard players operation #rps_diff ybih.config = @s ybih.rps_choice
scoreboard players operation #rps_diff ybih.config -= #rps_ai ybih.config
scoreboard players operation #rps_diff ybih.config += #c3 ybih.config
scoreboard players operation #rps_diff ybih.config %= #c3 ybih.config

# 对手那一手：三档各报一次，文案与上面算出来的编号一一对应
execute if score #rps_ai ybih.config matches 0 run tellraw @s {{TXT_S}}对手出了【石头】{{TXT_M}}gray{{TXT_E}}
execute if score #rps_ai ybih.config matches 1 run tellraw @s {{TXT_S}}对手出了【剪刀】{{TXT_M}}gray{{TXT_E}}
execute if score #rps_ai ybih.config matches 2 run tellraw @s {{TXT_S}}对手出了【布】{{TXT_M}}gray{{TXT_E}}

# 赢：连胜加一，够三连就在房里通报一声
# 通报用的是「以房间为原点的 @a[distance=..12]」，只有房里的人收得到；
# at 只换位置不换执行者，所以文案里的 @s 仍是出拳的这个人
execute if score #rps_diff ybih.config matches 1 run scoreboard players add @s ybih.rps_win 1
execute if score #rps_diff ybih.config matches 1 run tellraw @s [{{TXT_S}}赢了 · 当前连胜 {{TXT_E}},{{SCORE_RPSWIN}},{{TXT_S}} 场{{TXT_M}}green{{TXT_E}}]
execute if score #rps_diff ybih.config matches 1 run playsound minecraft:entity.player.levelup player @s ~ ~ ~ 1 1.4
execute if score #rps_diff ybih.config matches 1 if score @s ybih.rps_win matches 3.. at @e[tag=ybih_room,limit=1] run tellraw @a[distance=..12] [{{SEL_S}}@s{{SEL_E}},{{TXT_S}} 在等待室里连赢 {{TXT_E}},{{SCORE_RPSWIN}},{{TXT_S}} 场猜拳{{TXT_M}}gold{{TXT_E}}]

# 平：连胜既不续也不断
execute if score #rps_diff ybih.config matches 0 run tellraw @s {{TXT_S}}平手，连胜保持{{TXT_M}}yellow{{TXT_E}}
execute if score #rps_diff ybih.config matches 0 run playsound minecraft:ui.button.click player @s ~ ~ ~ 1 1.0

# 输：连胜清零
execute if score #rps_diff ybih.config matches 2 run scoreboard players set @s ybih.rps_win 0
execute if score #rps_diff ybih.config matches 2 run tellraw @s {{TXT_S}}输了，连胜断了{{TXT_M}}red{{TXT_E}}
execute if score #rps_diff ybih.config matches 2 run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.7

# 点击通道是「一次一用」：/trigger 提交后系统就把这个人关掉了，
# 不重新开口他只能玩一次。这里是这个通道唯一的续期点
scoreboard players enable @s ybih.trigger
