# ybih:util/build_wait_room —— 在集合点正上方建一间密闭等待室
# 四面不透光，没轮到的人关在里面看不到外面的藏匿者
# 基准高度由构建脚本按包注入：1.16–1.17 的建筑上限只到 255，包 1 只能用 245；
# 1.18 起可放置范围是 -64~319、自然地形最高到 256，包 2/3 抬到 300 避开山体
# 房子总高 5 格（地板 1 + 内空 3 + 顶 1），内部一律以标记为基准取相对坐标
# 它落在集合点正上方，而边界以集合点为中心，因此必定在边界之内

# 集合点可能挪过位置，先把上一间拆干净，免得天上的房子越留越多
function ybih:util/remove_wait_room
execute at @e[tag=ybih_center,limit=1] run summon armor_stand ~ {{WAIT_ROOM_Y}} ~ {Tags:["ybih_room"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~ ~-5 ~5 ~4 ~5 quartz_block
execute at @e[tag=ybih_room,limit=1] run fill ~-4 ~1 ~-4 ~4 ~3 ~4 air
execute at @e[tag=ybih_room,limit=1] run fill ~-1 ~4 ~-1 ~0 ~4 ~0 sea_lantern
