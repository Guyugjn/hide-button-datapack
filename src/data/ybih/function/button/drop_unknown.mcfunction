# ybih:button/drop_unknown —— 材质不在本包清单内的候选：只删标记，不碰方块
# 这种位置几乎都是地图自带的按钮，删方块会破坏地图

kill @e[tag=ybih_new,tag=ybih_unknown,distance=..2,limit=1,sort=nearest]
