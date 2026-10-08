# ybih:room/enter —— 把人送进等待室：落位、进门提示音、分名单位、贴名单、发一本说明
# 只有还在房外的人会走到这里（turn/gather 按距离分工），所以提示只发一次。
# 调用时执行位置仍是房间标记，这里的 ~ ~1 ~ 就是室内第一层，与集合点的小数无关

tp @s ~ ~1 ~
playsound minecraft:block.beacon.activate player @s ~ ~ ~ 1 1.2

# 先分名单位再贴名单：名单靠名单位的写死选择器取名字，没有位子就报不出名字
function ybih:room/ttt_seat
function ybih:room/ttt_roster
function ybih:room/ttt_status
function ybih:room/ttt_book

# 点击通道每次用过都会被系统关掉，进房时重新开口，人才能接着玩
scoreboard players set @s ybih.trigger 0
scoreboard players enable @s ybih.trigger
