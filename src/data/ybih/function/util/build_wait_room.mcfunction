# ybih:util/build_wait_room —— 在集合点正上方建一间等待室
# 四面与屋顶都不透光：没轮到的人关在里面看不到外面的藏匿者。
# 只有天窗朝上开着，等待的人能抬头看天，看不到地面，防窥的设计不受影响
# 基准高度由构建脚本按包注入：1.16–1.17 的建筑上限只到 255，包 1 只能用 245；
# 1.18 起可放置范围是 -64~319、自然地形最高到 256，包 2/3 抬到 300 避开山体
# 房子总高 5 格（地板 1 + 内空 3 + 顶 1），外壳 13×13、内空 11×11
# 内部一律以标记为基准取相对坐标（换包时只改一个数字）
# 它落在集合点正上方，而边界以集合点为中心，因此必定在边界之内
#
# 地板是浅灰地毯：turn/gather 靠「标记那一格是不是浅灰地毯」确认房子砌好了才往里送人。
# 改地板材质必须同步改那一行，否则等待者根本不会被送进房间（人还留在集合点）
#
# 地毯是「需要支撑」的方块：底下是空气时它会被瞬间崩掉，fill 虽然报成功，方块却一个不剩。
# 而这间房子是悬在天上的，掏空内空之后基准层下面本来就是空气 —— 所以必须先在基准层
# 下面垫一层实心板，地毯才待得住。这一层是地板的地基，不垫它整间房就没有地板，
# turn/gather 的守卫也就永远过不去（等待者只会被留在集合点，且没有任何报错）
# 上一版的地板是石英块：石英是实心方块、不需要支撑，所以垫层这件事当时不存在

# 集合点可能挪过位置，先把上一间拆干净，免得天上的房子越留越多
function ybih:util/remove_wait_room
execute at @e[tag=ybih_center,limit=1] run summon armor_stand ~ {{WAIT_ROOM_Y}} ~ {Tags:["ybih_room"],Marker:1b,Invisible:1b,NoGravity:1b,Invulnerable:1b}

# 外壳：深色橡木，13×13 实心砌到顶（四面都不透光）
execute at @e[tag=ybih_room,limit=1] run fill ~-6 ~ ~-6 ~6 ~4 ~6 dark_oak_planks
# 掏空内空：11×11、3 格高
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~1 ~-5 ~5 ~3 ~5 air

# 地板地基：基准层下面铺一层实心板，给地毯当支撑（顺序必须在铺地毯之前）
execute at @e[tag=ybih_room,limit=1] run fill ~-6 ~-1 ~-6 ~6 ~-1 ~6 dark_oak_planks
# 地板铺地毯：外圈棕色当走道，里圈浅灰当坐区（标记那一格必定落在里圈）
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~ ~-5 ~5 ~ ~5 brown_carpet
execute at @e[tag=ybih_room,limit=1] run fill ~-4 ~ ~-4 ~4 ~ ~4 light_gray_carpet

# 屋顶一圈荧石当灯带，正中 5×5 换成玻璃当天窗
execute at @e[tag=ybih_room,limit=1] run fill ~-3 ~4 ~-3 ~3 ~4 ~3 glowstone
execute at @e[tag=ybih_room,limit=1] run fill ~-2 ~4 ~-2 ~2 ~4 ~2 glass

# 四角地灯：地毯四角换成海晶灯，室内暖而不暗
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~ ~-5 ~-5 ~ ~-5 sea_lantern
execute at @e[tag=ybih_room,limit=1] run fill ~5 ~ ~-5 ~5 ~ ~-5 sea_lantern
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~ ~5 ~-5 ~ ~5 sea_lantern
execute at @e[tag=ybih_room,limit=1] run fill ~5 ~ ~5 ~5 ~ ~5 sea_lantern

# 南北两侧座位：深色橡木楼梯一字排开当长椅。
# 用楼梯而不是「坐板 + 靠背」两层方块，是因为靠背原本是摞在坐板上面的一整排 y=~2 方块，
# 它正下方那 9 格全是空气（只有四角有盆栽），看上去就是一排悬空的板子。
# 楼梯自带高半边当靠背、低半边当坐面，靠背与坐面同属一格，不会再脱节。
# 朝向决定高半边朝哪：facing=<方向> 时高半边朝该方向（由 blockstate 的 y 旋转决定）。
# 所以贴北墙那排用 facing=north（靠背贴墙、坐面朝房间中央），南墙那排用 facing=south。
# 排面直接落在最里一圈（~∓5）而不是往里缩一格，靠背才贴得住墙。
# 两端各留一格给四角的海晶灯与盆栽（它们占 x=~±5, z=~∓5）
execute at @e[tag=ybih_room,limit=1] run fill ~-4 ~ ~-5 ~4 ~ ~-5 dark_oak_stairs[facing=north]
execute at @e[tag=ybih_room,limit=1] run fill ~-4 ~ ~5 ~4 ~ ~5 dark_oak_stairs[facing=south]

# 四角盆栽：花盆里带花。带花的花盆是独立方块（potted_<花名>），不是给 flower_pot 加状态，
# 直接放 minecraft:flower_pot 只会得到一个空盆。两种花按对角对称摆，暖色配木屋
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~1 ~-5 ~-5 ~1 ~-5 potted_poppy
execute at @e[tag=ybih_room,limit=1] run fill ~5 ~1 ~-5 ~5 ~1 ~-5 potted_oxeye_daisy
execute at @e[tag=ybih_room,limit=1] run fill ~-5 ~1 ~5 ~-5 ~1 ~5 potted_oxeye_daisy
execute at @e[tag=ybih_room,limit=1] run fill ~5 ~1 ~5 ~5 ~1 ~5 potted_poppy
