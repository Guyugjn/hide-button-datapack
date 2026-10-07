# ybih:room/sparkle —— 天窗下飘一縷粒子（执行位置是房间标记）
# 只朝上走：房间的防窥设计是「四面与侧向都不能透」，天窗朝天才允许有动静
# 节拍在这里复位，等于「每 2 秒一次」由这一个数字决定

scoreboard players set #room_timer ybih.config 2
particle minecraft:end_rod ~ ~3.2 ~ 2.0 0.3 2.0 0.02 10 normal
