# ybih:room/enter —— 把人送进等待室：落位、进门提示音、给出猜拳的点击入口
# 只有还在房外的人会走到这里（turn/gather 按距离分工），所以提示只发一次。
# 调用时执行位置仍是房间标记，这里的 ~ ~1 ~ 就是室内第一层，与集合点的小数无关

tp @s ~ ~1 ~
playsound minecraft:block.beacon.activate player @s ~ ~ ~ 1 1.2

tellraw @s {{TXT_S}}等待室 · 有事可做{{TXT_M}}gold{{TXT_E}}
tellraw @s [{{BTN_RPS_ROCK}},{{TXT_S}}  {{TXT_E}},{{BTN_RPS_SCISSORS}},{{TXT_S}}  {{TXT_E}},{{BTN_RPS_PAPER}}]
tellraw @s {{TXT_S}}点一下出一拳；练出连胜会被通报{{TXT_M}}gray{{TXT_E}}

# 点击通道每次用过都会被系统关掉，进房时重新开口，人才能接着玩
scoreboard players set @s ybih.trigger 0
scoreboard players enable @s ybih.trigger
