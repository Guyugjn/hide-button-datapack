#!/usr/bin/env node
// ybih 数据包构建脚本：从 src/ 单一源生成 dist/ 下 3 个分版本包，并做静态校验
// 用法：node tools/build.mjs

import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  rmSync,
  readdirSync,
  statSync,
  existsSync,
} from 'node:fs';
import { join, dirname, relative, sep } from 'node:path';
import { deflateRawSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import {
  PACKS,
  MATERIAL_TO_BLOCK,
  MATERIAL_TO_TAG,
  bookCommand,
  tttBookCommand,
  TTT_BOOK_PAGES,
  SETTING_FUNCS,
  BUTTON_FACINGS,
  BOOK_PAGES,
  BOOK_LINES,
  BOOK_LINE_WIDTH,
  TEXT_JSON,
  TEXT_SNBT,
  HINT_RADII,
  HINT_RANGE_DEFAULT,
  pageContentRows,
  pageLines,
  textWidth,
} from '../src/manifest.mjs';
import { BLOCK_SINCE, sinceOf, versionAtLeast } from '../src/block_versions.mjs';
import { buildTttGenerated } from './ttt.mjs';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SRC = join(ROOT, 'src');
const SRC_DATA = join(SRC, 'data');
const DIST = join(ROOT, 'dist');

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walk(full));
    else out.push(full);
  }
  return out;
}

function writeFileDeep(target, content) {
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, content, 'utf8');
}

// ── 动态生成的文件 ───────────────────────────────────────────────

function genGiveButtons(pack) {
  const lines = [
    '# ybih:player/give_buttons —— 发放按钮（每种材质一个）',
    '#',
    '# 一、先清掉身上残留的按钮。上一轮没用掉的那一个、以及取消重放退回来的那一个，',
    '#     都会留在背包里；不清干净就会出现「手上有两个按钮、只藏了一个」这种情况。',
    '#     更麻烦的是残留会让玩家误判自己已经藏过，而场上少一个按钮，轮末计数也跟着错。',
    '#',
    '# 二、发放。背包塞满时 give 会把放不下的那几种丢在脚边，装备栏里一个都没多，',
    '#     玩家看到的却是「发了但没收到」，于是以为插件坏了。发完必须专门探一次脚边，',
    '#     命中就明说背包满了 —— 这是唯一能让玩家自己判断该怎么做的信号，不能省。',
    '',
    'clear @s #minecraft:buttons',
    '',
    '# 发之前先把脚边**旧**的按钮掉落物收掉。少了这一步，玩家很久以前随手丢在脚下的按钮',
    '# 会被当成这次的溢出，凭空报一次「背包满了」。范围取 1.5 格，只够覆盖脚下这一圈。',
  ];
  for (const m of pack.materials) {
    lines.push(
      `kill @e[type=item,distance=..1.5,nbt={Item:{id:"${MATERIAL_TO_BLOCK(m)}"}}]`,
    );
  }
  lines.push('');
  for (const m of pack.materials) lines.push(`give @s ${pack.give(m)} 1`);
  lines.push('');
  lines.push('# 只按 Item.id 这个字符串匹配，不碰 Age 之类的数值字段：');
  lines.push('# NBT 数值在匹配时要求标签类型一致，而 Age 存的是 short，写 Age:0 会被解析成 int，');
  lines.push('# 类型对不上就永远匹配不到 —— 那样这条检测会静默失效，比不写还糟。');
  lines.push('# 1.20.5 改过物品堆叠的序列化（Count→count、tag→components），但 Item.id 两层都一样，');
  lines.push('# 所以这条选择器在本包支持的整个版本区间内都成立');
  for (const m of pack.materials) {
    lines.push(
      `execute as @e[type=item,distance=..1.5,nbt={Item:{id:"${MATERIAL_TO_BLOCK(m)}"}}] run tag @s add ybih_overflow`,
    );
  }
  lines.push('');
  lines.push(
    'execute if entity @e[tag=ybih_overflow] run tellraw @s {{TXT_S}}你的背包放不下全部按钮，多出来的已经掉在脚边，捡起来就能接着藏{{TXT_M}}red{{TXT_E}}',
  );
  lines.push(
    'execute if entity @e[tag=ybih_overflow] run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 0.8',
  );
  lines.push('# 用完就摘掉：这个标记只服务于上面那次提示，留在掉落物上会被下一处误读');
  lines.push('tag @e[tag=ybih_overflow] remove ybih_overflow');
  return lines.join('\n') + '\n';
}

function genTagMaterial(pack) {
  const lines = ['# ybih:button/tag_material —— 给新标记实体打上材质标签，认不出的打上未知标记', ''];
  for (const m of pack.materials) {
    lines.push(
      `execute if block ~ ~ ~ ${MATERIAL_TO_BLOCK(m)} run tag @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] add ${MATERIAL_TO_TAG(m)}`,
    );
  }
  const notOurs = pack.materials.map((m) => `unless entity @s[tag=${MATERIAL_TO_TAG(m)}]`).join(' ');
  lines.push('');
  lines.push(
    `execute as @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] ${notOurs} run tag @s add ybih_unknown`,
  );
  return lines.join('\n') + '\n';
}

function genPressTick(pack) {
  return [
    '# ybih:button/press_tick —— 全服按钮只遍历一次，逐个交给 press_scan（待确认与往局残留的不参与）',
    '',
    'execute as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config at @s run function ybih:button/press_scan',
    '',
  ].join('\n');
}

// 单次遍历后的逐按钮分派：按材质标签做廉价判定，命中才读方块状态
function genPressScan(pack) {
  const lines = [
    '# ybih:button/press_scan —— 以按钮标记为执行者：判定是否被按下，并在弹起时解除处理标记',
    '',
  ];
  for (const m of pack.materials) {
    const tag = MATERIAL_TO_TAG(m);
    const block = MATERIAL_TO_BLOCK(m);
    lines.push(
      `execute if entity @s[tag=${tag}] if block ~ ~ ~ ${block}[powered=true] run function ybih:button/on_press`,
    );
    lines.push(
      `execute if entity @s[tag=${tag}] unless block ~ ~ ~ ${block}[powered=true] run function ybih:button/release`,
    );
  }
  return lines.join('\n') + '\n';
}

// 按钮位图：ybih.hit 挂在按钮标记上，记「谁从这个按钮上拿过分」，位号 = 玩家 ybih.id - 1。
// 记分板没有按位与，判定写成取模：hit % 2^id >= 2^(id-1) 等价于「第 id-1 位已置」。
// 位宽上限 30：再往上 2^id 会溢出 int32，所以编号超过 30 的掩码留 0，调用方据此拒绝并提示。
// 掩码与模数都算成常量分派，只在这一位玩家真的按下时执行一次，不进每 tick 循环
const HIT_BITS = 30;

function genHitBit(pack) {
  const lines = [
    '# ybih:button/hit_bit —— 按玩家编号算出他在按钮位图里的掩码（执行者是玩家）',
    '# #hit_bit = 2^(id-1) 是掩码，#hit_pow = 2^id 是取模用的模数',
    '# 编号超过位宽上限时两者都留 0，由 award_grant 判定为无法去重并拒绝',
    '',
    'scoreboard players set #hit_bit ybih.config 0',
  ];
  for (let id = 1; id <= HIT_BITS; id++) {
    lines.push(
      `execute if score @s ybih.id matches ${id} run scoreboard players set #hit_bit ybih.config ${2 ** (id - 1)}`,
    );
  }
  lines.push('');
  lines.push('scoreboard players operation #hit_pow ybih.config = #hit_bit ybih.config');
  lines.push('scoreboard players operation #hit_pow ybih.config *= #c2 ybih.config');
  return lines.join('\n') + '\n';
}

// 取消重放：把刚用掉的材质退回给玩家，让他能重新找位置
function genRefundPending(pack) {
  const lines = [
    '# ybih:button/refund_pending —— 取消重放时退回一个刚用掉的按钮（以玩家为执行者）',
    '',
  ];
  for (const m of pack.materials) {
    lines.push(
      `execute if entity @e[tag=ybih_pending,tag=${MATERIAL_TO_TAG(m)}] run give @s ${pack.give(m)} 1`,
    );
  }
  return lines.join('\n') + '\n';
}

// 提示半径：`distance=..N` 是选择器参数、只收字面量，代入不了记分板，只能按档位逐条分派。
// 不匹配的档位会被 if score 提前挡住，不会白遍历一遍实体
function genHintScan(pack) {
  const lines = [
    '# ybih:game/hint_scan —— 按设定的探测半径扫一遍场上标记',
    '# distance=..N 只收字面量、代入不了记分板，只能逐档分派',
    '',
  ];
  for (const r of HINT_RADII) {
    lines.push(
      `execute if score #hint_range ybih.config matches ${r} as @e[tag=ybih_button,distance=..${r}] if score @s ybih.era = #era ybih.config run function ybih:game/hint_probe`,
    );
  }
  return lines.join('\n') + '\n';
}

// 记录按钮朝向：材质 × 朝向逐组合判定，给新标记打上朝向标签
function genTagFace(pack) {
  const lines = ['# ybih:button/tag_face —— 记录按钮的朝向状态', ''];
  for (const m of pack.materials) {
    for (const f of BUTTON_FACINGS) {
      lines.push(
        `execute if block ~ ~ ~ ${MATERIAL_TO_BLOCK(m)}[${f.state}] run tag @e[tag=ybih_new,distance=..2,limit=1,sort=nearest] add ${f.tag}`,
      );
    }
  }
  return lines.join('\n') + '\n';
}

// 保护检测：全服按钮只遍历一次。位置没有按钮就记一次修复，未超限的交给还原函数，
// 超限的直接放弃 —— 水会反复把按钮冲掉，而每恢复一次就掉落一个按钮物品，
// 不封顶就成了刷物品机器
//
// 待确认的按钮（ybih_pending）不参与：那个位置玩家还没点确认，可能正要去取消重放。
// 保护机制插手会把方块摆回来、并开始累加 ybih.fixed，数到上限就把待确认标记
// 当成「保不住的按钮」直接收回、还通知物主被水冲毁了 —— 而这一切都发生在确认之前
// 遍历只做一次：全场实体遍历是全库最贵的操作，性能契约限定每 tick 至多一次。
// 逐按钮的三条判定搬进 protect_scan，由这一行的 run 逐实体调用 —— 实体是顺序求值的，
// 依次作用在同一个 @s 上与原来三行各遍历一遍的结果完全一致，代价降到三分之一
function genProtectCheck(pack) {
  const scan =
    'execute as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config at @s';
  return [
    '# ybih:button/protect_check —— 位置上没有按钮的交给 protect_scan（只处理本局登记的标记）',
    '# 全场遍历在这里只做一次，逐按钮的分派在 protect_scan 里',
    '',
    `${scan} unless block ~ ~ ~ #minecraft:buttons run function ybih:button/protect_scan`,
    '',
  ].join('\n');
}

// protect_scan：以按钮标记为执行者，由 protect_check 的遍历逐个调用。
// 外层已经筛过「本局登记、且位置上确实没有按钮」，这里只做记数与分派。
// 顺序与阈值都不能动：先记一次丢失，再按互斥且穷尽的两档分派 ——
// 数到 4 次就说明这个位置保不住，交给 give_up 收回，免得一直复制按钮物品
function genProtectScan(pack) {
  return [
    '# ybih:button/protect_scan —— 以按钮标记为执行者：累计丢失次数，按次数分派还原或放弃',
    '',
    'scoreboard players add @s ybih.fixed 1',
    'execute if score @s ybih.fixed matches ..3 run function ybih:button/protect_restore',
    'execute if score @s ybih.fixed matches 4.. run function ybih:button/give_up',
    '',
  ].join('\n');
}

// 还原：按注册时记录的材质与朝向 setblock 回来，只在按钮真的丢失时执行
function genProtectRestore(pack) {
  const lines = [
    '# ybih:button/protect_restore —— 按记录的材质与朝向还原被破坏的按钮',
    '',
  ];
  for (const m of pack.materials) {
    const block = MATERIAL_TO_BLOCK(m);
    const tag = MATERIAL_TO_TAG(m);
    for (const f of BUTTON_FACINGS) {
      lines.push(
        `execute if entity @s[tag=${tag},tag=${f.tag}] run setblock ~ ~ ~ ${block}[${f.state}]`,
      );
    }
  }
  return lines.join('\n') + '\n';
}

// 围观展示：把全体玩家放进按钮所在的那一格，视线对准按钮面板。
// 标记落在按钮方块的水平中心，所以位置一律是本格中心；只有视线方向按朝向分派 ——
// 贴地的面板在方块下半部（俯视）、贴天花板的面板吊在上半部（仰视）、
// 贴墙的面板贴在某一面墙上（朝那一面平视）。
// 视角贴着面板看，画面里基本只有按钮本身，周围环境看不到。
//
// 视线用 tp 的 yaw/pitch 绝对角度，不用 facing：
// facing 的目标点写 `~` 时以「执行者当前位置」为基准，而位置参数与角度参数在同一条命令里
// 一次性解析，转向的参考点不会跟着这次传送的结果走 —— 传送到位了、视线还落在传送前那一点上。
// 角度是纯数字、没有 `~` 基准，行为完全确定。
// yaw 按 wiki：-180 正北、-90 正东、0 正南、90 正西。
//
// 位置要比标记低一格：标记落在按钮方格的水平中心、y 在方格底面上，
// 而玩家脚底站到那一层会正好比按钮高一格，所以要往下让 1 格。
//
// 贴墙那四条要朝 facing 的**反方向**看：按钮的 facing 记的是它正面朝哪，
// 而正面正对着放它的人。实测「面朝 east 放，按钮数据是 west」，
// 所以要看这个按钮，得站回它正面那边 —— 也就是朝 facing 的反方向。
const SHOWCASE_AIMS = {
  floor: [0, 89], // 面板在方块下半部，几乎垂直往下看
  ceil: [0, -89], // 面板吊在上半部，几乎垂直往上看
  wall_n: [0, 0],
  wall_s: [-180, 0],
  wall_e: [90, 0],
  wall_w: [-90, 0],
};

function showcaseKey(tag) {
  const parts = tag.split('_'); // ybih_f_floor_n
  return parts[2] === 'wall' ? `wall_${parts[3]}` : parts[2];
}

function genShowcaseView(pack) {
  const lines = [
    '# ybih:game/showcase_view —— 把围观接管的人放进按钮那一格，视线对准按钮面板',
    '# 执行者是待展示按钮的标记实体：位置一律本格中心，只有朝向分派视线角度',
    '# 传送目标限定 ybih_show_nv：showcase_start 与 showcase_state 给「本轮被围观接管过的人」',
    '# 打的就是这个标记，showcase_end 也按它回收夜视 —— 传送范围与清理口径同源，不会漏人',
    '',
  ];
  const tags = [];
  for (const f of BUTTON_FACINGS) {
    const [yaw, pitch] = SHOWCASE_AIMS[showcaseKey(f.tag)];
    lines.push(
      `execute if entity @s[tag=${f.tag}] at @s run tp @a[tag=ybih_show_nv] ~ ~-1 ~ ${yaw} ${pitch}`,
    );
    tags.push(f.tag);
  }
  // 十二条朝向一条都没命中的标记（朝向标签被外部命令破坏或丢失）不能让围观空转：
  // 照原样原地待着，至少标题和 Boss 栏照常报进度。这条兜底不带位置偏移，
  // 因为它本来就不确定站在哪，硬挪反而可能把人塞进地形里
  const noneMatched = tags.map((t) => `unless entity @s[tag=${t}]`).join(' ');
  lines.push(`execute at @s ${noneMatched} run tp @a[tag=ybih_show_nv] ~ ~ ~`);
  return lines.join('\n') + '\n';
}

// 传送后的定格：玩家还按着方向键、客户端又已经按旧速度预测了位移，
// 刚被 tp 到新位置就会顺着原来的方向飞出去。定格期间每 tick 把所有人拉回同一个位置，
// 把输入造成的那一段位移压掉。
// 只用位置参数、**不带角度** —— 带上角度会连玩家的视角一起锁死，转不了头看周围。
function genShowcasePin(pack) {
  const lines = [
    '# ybih:game/showcase_pin —— 定格期间把围观接管的人按回站位，只设位置、不设角度',
    '# 执行者是待展示按钮的标记实体；玩家在定格期间仍然可以自由转视角',
    '# 传送目标与 showcase_view 严格同源（ybih_show_nv）：两处只要有一处对不上，',
    '# 被传过来的人下一 tick 就不会被按回站位，站着站着就飘走了',
    '',
  ];
  const tags = [];
  for (const f of BUTTON_FACINGS) {
    lines.push(`execute if entity @s[tag=${f.tag}] at @s run tp @a[tag=ybih_show_nv] ~ ~-1 ~`);
    tags.push(f.tag);
  }
  // 与 showcase_view 同样的兜底：一条朝向都没命中时留在原地，不硬挪
  const noneMatched = tags.map((t) => `unless entity @s[tag=${t}]`).join(' ');
  lines.push(`execute at @s ${noneMatched} run tp @a[tag=ybih_show_nv] ~ ~ ~`);
  return lines.join('\n') + '\n';
}

function genClearPlacedBlocks(pack) {
  return [
    '# ybih:util/clear_placed_blocks —— 把注册过的按钮方块还原成空气',
    '# 先确认该位置仍是按钮，避免误删地图上的普通方块',
    '',
    'execute as @e[type=armor_stand,tag=ybih_button] at @s if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ minecraft:air',
    '',
  ].join('\n');
}

function genAdminBook(pack) {
  return [
    '# ybih:admin/book —— 发放管理员设置书',
    '',
    bookCommand(pack),
    '',
  ].join('\n');
}

// Boss 栏进度条：value 是命令参数里的整数常量，代入不了记分板，只能把剩余比例逐档分派
function genBarValue(pack) {
  const lines = [
    '# ybih:game/bar_value —— 把剩余比例（#pct，0–100）写进 Boss 栏进度条',
    '',
  ];
  for (let i = 0; i <= 100; i++) {
    lines.push(`execute if score #pct ybih.config matches ${i} run bossbar set ybih:timer value ${i}`);
  }
  return lines.join('\n') + '\n';
}

// 可放置白名单：按包的版本下限过滤掉尚未加入的方块，否则引用不存在的方块会让整个
// 标签加载失败，冒险模式下一个按钮都放不下去。
//
// 三个包的区间下限都在 1.16.2 之后，标签条目全程支持 required 字段，
// 所以对象写法可以直接透传，不需要版本分支。
function genPlaceableSurfaces(pack) {
  const src = readFileSync(join(SRC_DATA, 'ybih/tags/block/placeable_surfaces.json'), 'utf8');
  const parsed = JSON.parse(src);
  const out = [];
  for (const entry of parsed.values) {
    const isObject = typeof entry === 'object' && entry !== null;
    const id = isObject ? entry.id : entry;
    // 方块 ID 要按版本过滤；跨版本标签（#minecraft:mineable/* 之类）保留 required 写法
    // 这里查不到就照写（默认 1.16），由 validate 那边报错 —— 两个默认值刻意拆开，
    // 免得同一条错误逻辑把自己验证通过
    if (!id.startsWith('#')) {
      const since = sinceOf(id) ?? '1.16';
      if (!versionAtLeast(pack.minVersion, since)) continue;
    }
    out.push(entry);
  }
  return JSON.stringify({ values: out }, null, 2) + '\n';
}

// 放置校验：按钮泡在水里或会被水漫进来就作废。
//
// 水源与流水都要判：裸 water 是水源（level=0），water[level=1..7] 是流水。
// 只写裸 water 会漏掉流动中的水，而那恰恰会把按钮冲掉、掉落物品，
// 与保护机制来回拉锯就成了刷物品。逐 level 展开由构建期生成，避免手写 80 行。
//
// 只看水能来的方向：四个水平邻格加正上方。水不向上流，正下方不必拦
// （桥面、水下天花板照常能藏）；含水的方块不算（里面的水是困住的）。
const FLUID_NEIGHBORS = ['~1 ~ ~', '~-1 ~ ~', '~ ~ ~1', '~ ~ ~-1', '~ ~1 ~'];

function genFluidCheck(pack) {
  const lines = [
    '# ybih:button/fluid_check —— 按钮泡在水里或会被水漫进来就作废',
    '# 执行者是刚登记的按钮标记',
    '#',
    '# Java 版里按钮存不住水：尝试放置会被水替换、方块破坏掉落，流水同样会冲掉它。',
    '# 只拦流水挡不住水下、池底、水下建筑墙面这些位置，所以有邻格是水就一律作废。',
    '#',
    '# 水源与流水都要判：裸 water 是水源（level=0），water[level=1..7] 是流水。',
    '# 岩浆同理。本文件由 tools/build.mjs 生成，改判据请改那边的 FLUID_NEIGHBORS。',
    '#',
    '# 只看水能来的方向：四个水平邻格加正上方。水不会向上流，正下方是水不必拦，',
    '# 桥下、水下天花板那类位置照常能藏。',
    '# 含水的方块（含水楼梯、含水栅栏那类）不算：里面的水是困住的，不会流出来。',
    '',
    'scoreboard players set #wet ybih.config 0',
    '',
  ];
  for (const fluid of ['water', 'lava']) {
    lines.push(`# ${fluid === 'water' ? '水' : '岩浆'}：源 + 流动各级`);
    for (const pos of FLUID_NEIGHBORS) {
      lines.push(`execute if block ${pos} ${fluid} run scoreboard players set #wet ybih.config 1`);
    }
    for (let level = 1; level <= 7; level++) {
      for (const pos of FLUID_NEIGHBORS) {
        lines.push(
          `execute if block ${pos} ${fluid}[level=${level}] run scoreboard players set #wet ybih.config 1`,
        );
      }
    }
    lines.push('');
  }
  return lines.join('\n');
}

// 等待室九宫格棋的全部生成器都在 tools/ttt.mjs：棋盘跟着人走，
// 所以同一份代码同时服务任意多局，不再有固定桌数
const TTT_GENERATED = buildTttGenerated(tttBookCommand);

const GENERATED = {
  ...TTT_GENERATED,
  'data/ybih/function/player/give_buttons.mcfunction': genGiveButtons,
  'data/ybih/function/button/tag_material.mcfunction': genTagMaterial,
  'data/ybih/function/button/tag_face.mcfunction': genTagFace,
  'data/ybih/function/button/press_tick.mcfunction': genPressTick,
  'data/ybih/function/button/press_scan.mcfunction': genPressScan,
  'data/ybih/function/button/hit_bit.mcfunction': genHitBit,
  'data/ybih/function/button/protect_check.mcfunction': genProtectCheck,
  'data/ybih/function/button/protect_scan.mcfunction': genProtectScan,
  'data/ybih/function/button/protect_restore.mcfunction': genProtectRestore,
  'data/ybih/function/button/refund_pending.mcfunction': genRefundPending,
  'data/ybih/function/admin/book.mcfunction': genAdminBook,
  'data/ybih/function/util/clear_placed_blocks.mcfunction': genClearPlacedBlocks,
  'data/ybih/function/game/bar_value.mcfunction': genBarValue,
  'data/ybih/function/game/showcase_view.mcfunction': genShowcaseView,
  'data/ybih/function/game/showcase_pin.mcfunction': genShowcasePin,
  'data/ybih/function/game/hint_scan.mcfunction': genHintScan,
  'data/ybih/function/button/fluid_check.mcfunction': genFluidCheck,
  'data/ybih/tags/block/placeable_surfaces.json': genPlaceableSurfaces,
};

// ── 目录名映射 ───────────────────────────────────────────────────

function targetPaths(pack, relPath) {
  const outs = [];

  const map = (prefix, pluralPrefix, wantPlural, wantSingular) => {
    const tail = relPath.slice(prefix.length);
    if (wantPlural) outs.push(pluralPrefix + tail);
    if (wantSingular) outs.push(prefix + tail);
  };

  if (relPath.startsWith('data/ybih/function/')) {
    map('data/ybih/function/', 'data/ybih/functions/', pack.pluralFunctions, pack.singularFunctions);
    return outs;
  }
  if (relPath.startsWith('data/minecraft/tags/function/')) {
    map(
      'data/minecraft/tags/function/',
      'data/minecraft/tags/functions/',
      pack.pluralFunctions,
      pack.singularFunctions,
    );
    return outs;
  }
  if (relPath.startsWith('data/ybih/tags/block/')) {
    map('data/ybih/tags/block/', 'data/ybih/tags/blocks/', pack.pluralTags, pack.singularTags);
    return outs;
  }
  if (relPath.startsWith('data/ybih/advancement/')) {
    map('data/ybih/advancement/', 'data/ybih/advancements/', pack.pluralAdv, pack.singularAdv);
    return outs;
  }
  return [relPath];
}

// ── 占位符替换 ───────────────────────────────────────────────────

function substitute(text, tokens) {
  let out = text;
  for (const [key, value] of Object.entries(tokens)) {
    out = out.split(`{{${key}}}`).join(value);
  }
  return out;
}

// ── 构建单个包 ───────────────────────────────────────────────────

function buildPack(pack) {
  const outDir = join(DIST, pack.id);
  rmSync(outDir, { recursive: true, force: true });
  mkdirSync(outDir, { recursive: true });

  // pack.mcmeta
  const mcmeta = {
    pack: {
      description: `你的按钮我来藏 (${pack.label})`,
      ...pack.mcmeta,
    },
  };
  writeFileDeep(join(outDir, 'pack.mcmeta'), JSON.stringify(mcmeta, null, 2) + '\n');

  // 源文件
  const sourceFiles = walk(SRC_DATA).map((f) => ({
    rel: 'data/' + relative(SRC_DATA, f).split(sep).join('/'),
    abs: f,
  }));

  const emitted = new Map(); // relPath -> content
  for (const { rel, abs } of sourceFiles) {
    if (GENERATED[rel]) continue; // 由生成器负责
    emitted.set(rel, readFileSync(abs, 'utf8'));
  }
  for (const [rel, gen] of Object.entries(GENERATED)) {
    emitted.set(rel, gen(pack));
  }
  // 只在部分版本区间成立的源文件由各包自己声明不发出。
  // 典型是进度条件：1.20 把 location 从裸对象收成谓词数组，同一份 JSON 不可能两边都合法，
  // 于是分两个文件并存，不适用它的包把用不上的那份摘掉，免得每次加载都多一条解析错误。
  // 声明了却对不上任何源文件是配置写错了，直接中断构建
  for (const rel of pack.skipFiles ?? []) {
    if (!emitted.has(rel)) {
      throw new Error(`包 ${pack.id} 的 skipFiles 声明了不存在的文件：${rel}`);
    }
    emitted.delete(rel);
  }

  // 每个可选数值一个函数：改完值统一走反馈函数，保证有点击音效与回执
  for (const setting of SETTING_FUNCS) {
    const lines = [
      `# ybih:config/${setting.name} —— 设置 ${setting.score} = ${setting.value}`,
      '',
      `scoreboard players set ${setting.score} ybih.config ${setting.value}`,
    ];
    if (setting.after) lines.push(setting.after);
    lines.push('function ybih:config/notify');
    emitted.set(`data/ybih/function/config/${setting.name}.mcfunction`, lines.join('\n') + '\n');
  }

  for (const [rel, raw] of emitted) {
    const content = substitute(raw, { ...pack.tokens, WAIT_ROOM_Y: String(pack.waitRoomY) });
    for (const target of targetPaths(pack, rel)) {
      writeFileDeep(join(outDir, ...target.split('/')), content);
    }
  }

  return outDir;
}

// ── 静态校验 ─────────────────────────────────────────────────────

// 扫描引号字符串里的非法转义：字符串按 Brigadier 的规则只接受 \" \' \\ 三种；
// 1.21.5 起组件写在 SNBT 里，SNBT 还认 \n \t \b \f \r \x \u 这些转义
//
// 一次从左到右的扫描，遇到引号就成对推进，并记住当前处在哪种引号里。
// 不能像早先那样「对 " 与 ' 各扫一遍、互不知道对方」：文案里的撇号
// （英文所有格、缩写）会被第二遍当成单引号串的开头，一路扫到下一个撇号，
// 途中合法的 \" 就被判成非法转义。实测 `…don't…a\"b…` 会误报。
function findBadEscapes(line, snbt) {
  const extra = snbt ? ['n', 't', 'b', 'f', 'r', 'x', 'u'] : [];
  const bad = [];
  let i = 0;
  while (i < line.length) {
    const quote = line[i];
    if (quote !== '"' && quote !== "'") {
      i++;
      continue;
    }
    // 进入一个字符串：一直走到同种引号的收尾。
    // 合法转义就是上面那三种（外加 SNBT 的 \n \t 等），与开引号是哪种无关 ——
    // 判定放宽到「不是这三种」才报错，宁可漏报也不误报：这是构建闸门，
    // 挡住一次合法构建的代价远大于放过一个真转义错误
    let j = i + 1;
    while (j < line.length && line[j] !== quote) {
      if (line[j] === '\\') {
        const next = line[j + 1];
        const legal = next === '"' || next === "'" || next === '\\' || extra.includes(next);
        if (!legal) bad.push(`\\${next}`);
        j += 2;
        continue;
      }
      j++;
    }
    i = j + 1;
  }
  return bad;
}

// 把一行里的字符串字面量抹成空格，只留下命令语法本身。
// 校验都是正则驱动的，而 tellraw 的文案是散文：里面有 if / unless / forceload
// 这类词就会被当成命令语法，既误报（构建直接失败）又掩盖真问题。
// 双引号与单引号都要认（1.21.5 起组件写在 SNBT 里，用的是单引号），
// 反斜杠转义要跳过，且只在行内配对 —— 一行里落单的引号不该吃到别的行。
// 字符串区间整段换成空格，既避免把两侧的 token 粘起来造出假 token，
// 又保证结果与原文逐字符同长，需要时可按同一位置回原文取参数
function stripStringLiterals(line) {
  const chars = line.split('');
  let i = 0;
  while (i < chars.length) {
    const quote = chars[i];
    if (quote !== '"' && quote !== "'") {
      i++;
      continue;
    }
    // 先确认行内有同类闭引号：落单的引号不当作字符串起点，
    // 否则它会把后面的命令一并抹掉，反倒制造漏检
    let closed = -1;
    for (let j = i + 1; j < chars.length; j++) {
      if (chars[j] === '\\') {
        j++;
        continue;
      }
      if (chars[j] === quote) {
        closed = j;
        break;
      }
    }
    if (closed < 0) {
      i++;
      continue;
    }
    for (let j = i; j <= closed; j++) chars[j] = ' ';
    i = closed + 1;
  }
  return chars.join('');
}

// 切出一行里所有配对的 {...} 片段，字符串里的花括号不参与配对。
// clickEvent / click_event 的键序与冒号后的空格都不固定（JSON 与 SNBT 两套写法并存），
// 靠写死顺序的正则去抓 run_command 的命令值会漏掉等价写法，所以先切对象再逐字段读
function objectSlices(line) {
  const out = [];
  const opened = [];
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (quote) {
      if (ch === '\\') i++;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") quote = ch;
    else if (ch === '{') opened.push(i);
    else if (ch === '}' && opened.length > 0) out.push(line.slice(opened.pop(), i + 1));
  }
  return out;
}

// 读出一个对象片段里的「引号键: 引号值」对。值只取字符串形态，
// 嵌套对象与数组不进这张表（它们另有自己的片段）
function readStringFields(obj) {
  const fields = {};
  const re = /(["'])([A-Za-z_][A-Za-z0-9_]*)\1\s*:\s*(["'])((?:\\.|(?!\3)[^\\])*)\3/g;
  for (const m of obj.matchAll(re)) fields[m[2]] = m[4].replace(/\\(.)/g, '$1');
  return fields;
}

// 一个坐标：可写绝对数（0 / 12.5 / -3），也可带相对或局部前缀（~ ~1 ~-3 ^2）
const COORD_RE = /^(?:[~^]-?(?:\d+(?:\.\d+)?|\.\d+)?|-?(?:\d+(?:\.\d+)?|\.\d+))$/;

// 命令后面跟着的一串参数（到行尾为止），按空白切开。
// 用来做与写法无关的按个数判定 —— 把空格数、相对坐标的具体写法写死进正则，
// 正是缺陷 7 里 forceload 检查「该拦的漏、不该拦的误报」的根源
function commandArgs(code, cmd) {
  const m = new RegExp(`(?:^|\\s)${cmd}(?=\\s|$)([\\s\\S]*)$`).exec(code);
  return m ? m[1].split(/\s+/).filter(Boolean) : [];
}

// tellraw 的组件列表里漏逗号（`[{...}{...}]`）是 SNBT/JSON 解析错误，
// 后果与漏 execute 同级：**整个函数文件不加载**，只往日志留一行 Whilst parsing command。
// 这个坑真的踩过 —— room/ttt_notice 末尾两条兜底语句漏了一个逗号，
// 邀请提示整条哑掉，而紧随其后的 told 标记照常置位，于是提示再也不发，
// 表现为「只有点刷新才看得到被邀请」。构建期拦下最省事。
//
// 判据只认 `}` 紧跟 `{`：两个对象之间漏逗号是这里唯一的真信号。
// **不要顺手加 `]` 紧跟 `[`** —— `tellraw @a[选择器] [组件列表]` 天然就长这样，
// 加了会把好行全判成错的（这一版就踩过，构建当场把 enter_searching_rotate 误报出来）。
// 也要排除未替换的 {{记号}}：`}}{{` 会在第二个 } 与 { 之间命中，那属于占位符问题，另有校验管
function findMissingComma(code) {
  if (/\}\}\{\{/.test(code)) return false;
  return /\}\s*\{/.test(code);
}

// 剥掉字符串后每一列的花括号嵌套深度。用来区分「命令的真参数块」与「那条命令载荷里的 NBT」：
// 原版标签只该在命令自身的参数里引用；NBT 里的标签名由解析器当字符串处理，
// 不查白名单、游戏也照常工作，混在一起查会把好好的行判成错误
function codeBraceDepth(code) {
  const depth = new Array(code.length).fill(0);
  let cur = 0;
  for (let i = 0; i < code.length; i++) {
    if (code[i] === '}') cur = Math.max(0, cur - 1);
    depth[i] = cur;
    if (code[i] === '{') cur++;
  }
  return depth;
}

// 音效 id 白名单。playsound 的音效是「直接引用」而不是注册表查询：
// 写错一个字符既不报错也不影响函数加载，只是什么声音都不放 —— 全库 13 处
// playsound 里有 1 处把 block.stone_button.click_on 写成了 click_on_block，
// 静默无声就是这么来的。id 的 minecraft: 前缀可以省略，两边写法都合法
const KNOWN_SOUND_IDS = new Set([
  'block.beacon.activate',
  'block.note_block.bass',
  'block.stone_button.click_on',
  'entity.player.levelup',
  'ui.button.click',
]);

// 粒子 id 白名单，与音效同理：粒子的通道名也是按名字查表，
// 写错既不报错也不影响函数加载，只是这一条静默什么都不显示。
// 跨 1.16–26.2 只用 1.13 起就存在的几种，别用后来才加的
const KNOWN_PARTICLE_IDS = new Set(['end_rod', 'flame', 'happy_villager']);

// 原版标签引用白名单。命令与进度 JSON 两条路径共用：
// 命令里引用不存在的标签是解析错误，整行不执行；进度里的标签写错则不报错，
// 只是条件永远不匹配 —— 两种都只写日志、不进聊天栏，只能在这里拦住。
// 命令这一侧走剥离后的文本，并要求引用点不在「命令载荷的花括号」里面：
// NBT 里的标签名按字符串处理，不受白名单约束，混进来会把好好的行判成错误
function checkVanillaTags(rel, text, errors, isCommand, lineNo = 0, depth = null) {
  const where = isCommand ? `${rel}:${lineNo}` : rel;
  for (const m of text.matchAll(/#minecraft:([a-z0-9_/]+)/g)) {
    if (isCommand && depth !== null && depth[m.index] > 0) continue;
    if (!KNOWN_VANILLA_TAGS.has(m[1])) {
      errors.push(`引用了未登记的原版标签 #minecraft:${m[1]} 于 ${where}`);
    }
  }
}

// 最高支持版本是否早于某个版本。版本串形态不合格时只报「读不出上限」，
// 不在这里重复报警，也不把拿不准的情况当成通过
function maxVersionLowerThan(maxVersion, bound) {
  if (maxVersion === null || maxVersion === undefined) return false;
  return !versionAtLeast(maxVersion, bound);
}

// 包的版本上限。label 形如「1.16.2 – 1.20.4」，破折号右边就是上限。
// 核对进度条件的版本配对时上限与下限缺一不可：item_used_on_block 是
// 「上限早于 1.20.5 才有」，只看下限会把包 1 里那份完全合法的旧进度判成过期
function packMaxVersion(pack, errors) {
  const parts = String(pack.label ?? '').split(/[–—−-]/);
  const last = parts[parts.length - 1].trim();
  if (!/^\d+(?:\.\d+)*$/.test(last)) {
    errors.push(
      `包 ${pack.id} 的 label「${pack.label}」里读不出最高支持版本，无法核对进度条件的版本配对`,
    );
    return null;
  }
  return last;
}

// 按版本才有的命令与子命令。用在低于其引入版本的包里会让整行解析失败，
// 而函数加载失败只写进日志、不进聊天栏，进游戏只会看到「什么都没发生」。
// 键是命令特征的匹配式，值是它开始存在的版本。
//
// 选择器参数（tag / scores / gamemode / limit / distance / sort）不在这里：
// 它们全部是 1.13 就有的，而三个包的下限是 1.16.2 / 1.20.5 / 1.21.5，
// 写进去也永远触发不了 —— 空转的 guard 只会让人误以为「这个参数受版本保护」。
const VERSION_GATED = [
  { re: /\brun return\b|^\s*return\b/, since: '1.20.2', what: '/return' },
  { re: /\bexecute\s+if\s+items\b/, since: '1.20.5', what: 'execute if items' },
  { re: /\bexecute\s+if\s+loaded\b/, since: '1.20.5', what: 'execute if loaded' },
  { re: /\bexecute\s+if\s+stopwatch\b/, since: '1.21.5', what: 'execute if stopwatch' },
  { re: /\bexecute\s+if\s+biome\b/, since: '1.19.4', what: 'execute if biome' },
  { re: /\bexecute\s+if\s+dimension\b/, since: '1.19', what: 'execute if dimension' },
  { re: /\bdata\s+modify\b/, since: '1.20.2', what: '/data modify' },
  { re: /\brandom\s+value\b/, since: '1.20.2', what: '/random' },
];

// 命令里能引用的原版标签白名单。引用不存在的标签会让 Brigadier 解析失败，
// 进而导致整个函数不加载 —— 而函数加载失败只写进日志、不进聊天栏，排查代价极高。
// 新用到原版标签时必须先确认它真的存在（查对应版本的 jar 里的 tags 目录），再加到这里。
const KNOWN_VANILLA_TAGS = new Set([
  'buttons', // 1.13 起一直存在，方块与物品两套注册表都有
  'mineable/axe',
  'mineable/pickaxe',
  'mineable/shovel',
  'mineable/hoe', // 1.17 起才有，引用处都带 required:false
]);

// /execute 的条件子命令白名单。写错名字（如 `if team`）是解析错误，
// 整行不执行、也不会有任何提示，只能靠这条校验兜住。
// 名单取自 wiki 的 /execute 语法树；跨 1.16–26.2 取并集，
// 新版本才有的几种（items / loaded / stopwatch）本项目没用，列上不影响旧版本
const EXECUTE_CONDITIONS = new Set([
  'biome',
  'block',
  'blocks',
  'data',
  'dimension',
  'entity',
  'function',
  'items',
  'loaded',
  'predicate',
  'score',
  'stopwatch',
]);

function validate(packDir, pack) {
  const errors = [];
  const files = walk(packDir);
  const maxVersion = packMaxVersion(pack, errors);

  for (const f of files) {
    const rel = relative(packDir, f).split(sep).join('/');
    if (f.endsWith('.json')) {
      let parsed = null;
      try {
        parsed = JSON.parse(readFileSync(f, 'utf8'));
      } catch (e) {
        errors.push(`JSON 非法 ${rel}：${e.message}`);
      }
      // 进度的条件结构写错时 JSON 依然合法、加载也不报错，只是**永远不匹配** ——
      // 表现成「按下去毫无反应」，比语法错误难查得多。
      // 1.20 起 location 必须是谓词数组（每个元素带 condition），写成裸对象就是死条件；
      // 但 1.16.2–1.19.4 那边 location 本来就是裸对象，所以下限早于 1.20 的包放行对象写法。
      // 判定按「触发器与 location 形态的配对」走，而不是按包下限恒真：
      //   · item_used_on_block 是 1.20.5 起被 any_block_use 取代的老触发器，
      //     只允许落在最高支持版本早于 1.20.5 的包里（本仓库就是包 1，它一直到 1.20.4 都要认这份旧语法）；
      //   · any_block_use 是 1.20.5 起才有的新触发器，只允许落在最低支持版本不早于 1.20.5 的包里。
      // 裸对象形态的 location 只在 1.20（23w18a）之前合法 —— 那次改动把 placed_block /
      // item_used_on_block / allay_drop_item_on_block 的 location 一并收成了谓词数组，
      // 分界线是 1.20 而不是 1.20.5（1.20.5 换的只是触发器名字）。
      // 包 1 横跨这条线：它在 1.16.2–1.19.4 要认裸对象、在 1.20–1.20.4 要认数组，
      // 所以 button_used_legacy.json 在包 1 覆盖的 1.20+ 上必然解析失败（只写日志、
      // 不影响另一份加载），这是为了让一份产物覆盖两端而付出的代价。
      // 因此裸对象只准出现在 *_legacy.json 里，别处出现就是漏改的真缺陷；
      // 而包 2/3 的下限在 1.20 之后，两份都该用数组。
      if (parsed && rel.includes('advancement')) {
        for (const [name, crit] of Object.entries(parsed.criteria ?? {})) {
          const loc = crit?.conditions?.location;
          if (loc === undefined) continue;
          const trigger =
            typeof crit.trigger === 'string'
              ? crit.trigger.replace(/^minecraft:/, '')
              : null;
          if (trigger === 'item_used_on_block' && !maxVersionLowerThan(maxVersion, '1.20.5')) {
            errors.push(
              `进度触发器 item_used_on_block 是 1.20.5 前的老写法，本包最高支持版本 ${maxVersion ?? '未知'} 已不再接受它 于 ${rel} 的 ${name}`,
            );
          }
          if (trigger === 'any_block_use' && !versionAtLeast(pack.minVersion, '1.20.5')) {
            errors.push(
              `进度触发器 any_block_use 是 1.20.5 起才有的，本包下限 ${pack.minVersion} 用不了 于 ${rel} 的 ${name}`,
            );
          }
          if (!Array.isArray(loc)) {
            // 裸对象的合法性只取决于「本包认不认 1.20 之前的写法」，与触发器无关。
            // 文件名以 _legacy 结尾的那份就是专门给 1.16.2–1.19.4 用的，
            // 它在包 1 里是必需的（在 1.20+ 上解析失败属于既定代价，见上面的说明）；
            // 包 2/3 的 skipFiles 已经把它摘掉，若还能走到这里说明 skipFiles 被人改坏了。
            // 反过来，裸对象出现在非 _legacy 的进度里就是漏改 —— 那种进度在 1.20+ 上
            // 结构不合法、整份作废，表现成「按下去毫无反应」。
            const isLegacyFile = /_legacy\.json$/.test(rel);
            if (!isLegacyFile) {
              errors.push(
                `进度条件 location 必须是谓词数组（1.20 起 location 收成数组；只有 *_legacy.json 才允许裸对象）于 ${rel} 的 ${name}`,
              );
              continue;
            }
            if (versionAtLeast(pack.minVersion, '1.20')) {
              errors.push(
                `包 ${pack.id} 的下限 ${pack.minVersion} 已在 1.20 之后，不再需要 *_legacy.json 于 ${rel}`,
              );
            }
            if (typeof loc !== 'object' || loc === null || loc.block === undefined) {
              errors.push(
                `进度条件 location 写成裸对象时必须是含 block 字段的对象 于 ${rel} 的 ${name}`,
              );
            }
            continue;
          }
          for (const [i, entry] of loc.entries()) {
            if (typeof entry !== 'object' || entry === null || typeof entry.condition !== 'string') {
              errors.push(`进度条件 location[${i}] 缺少 condition 字段于 ${rel} 的 ${name}`);
            }
          }
        }
      }
      // 原版标签白名单对进度里的条件同样适用：进度里的标签写错不会让进度解析失败，
      // 只是条件永远不匹配，比命令那边更隐蔽
      if (parsed) checkVanillaTags(rel, JSON.stringify(parsed), errors, false);
    }
    const text = readFileSync(f, 'utf8');
    const ph = text.match(/\{\{[A-Z0-9_]+\}\}/);
    if (ph) errors.push(`未替换的占位符 ${ph[0]} 于 ${rel}`);

    if (f.endsWith('.mcfunction')) {
      let lineNo = 0;
      for (const line of text.split('\n')) {
        lineNo++;
        if (line.trimStart().startsWith('#')) continue;
        const bad = findBadEscapes(line, pack.bookStyle === 'component-snbt');
        if (bad.length) {
          errors.push(`非法转义 ${[...new Set(bad)].join(' ')} 于 ${rel}:${lineNo}`);
        }
        // 语法类检查一律跑在剥离字符串字面量之后的文本上：
        // 文案里出现 if / unless / forceload 这类词不该被当成命令语法
        const code = stripStringLiterals(line);
        // 组件列表漏逗号会让整个函数不加载，且报错只进日志、不进聊天栏，
        // 排查代价极高（表现为「某个提示莫名其妙不发」），构建期直接拦下
        if (findMissingComma(code)) {
          errors.push(
            `组件列表漏了逗号（出现 }{ 相邻），整份函数会静默不加载 于 ${rel}:${lineNo}`,
          );
        }
        const depth = codeBraceDepth(code);
        const args = commandArgs(code, 'forceload');
        if (args.length > 0) {
          if (args[0] === 'all' || args[0] === 'remove' || args[0] === 'add') {
            const rest = args.slice(1);
            const removeAll = args[0] === 'remove' && rest.length === 1 && rest[0] === 'all';
            const coords = removeAll ? 0 : rest.length;
            if (!removeAll && coords % 2 !== 0) {
              errors.push(`forceload 的坐标必须成对（2 个或 4 个），这里有 ${coords} 个 于 ${rel}:${lineNo}`);
            }
            if (!removeAll && rest.some((a) => !COORD_RE.test(a))) {
              errors.push(`forceload 的参数里有不是坐标的：${rest.join(' ')} 于 ${rel}:${lineNo}`);
            }
          } else {
            errors.push(
              `forceload 只接受 add / remove（remove 可以带 all），这里是 ${args[0]} 于 ${rel}:${lineNo}`,
            );
          }
        }
        // 点击执行的命令必须带 / 前缀，否则客户端拒绝执行。
        // clickEvent 的键序与冒号后的空格都不固定（JSON 与 SNBT 两套写法并存），
        // 所以先切出对象片段再逐字段读，而不是把顺序写死进正则
        for (const obj of objectSlices(line)) {
          const fields = readStringFields(obj);
          const action = (fields.action ?? '').replace(/^minecraft:/, '');
          if (action !== 'run_command') continue;
          const cmd = fields.value ?? fields.command;
          if (typeof cmd !== 'string') continue;
          // 值本身一定以 / 开头，客户端才肯执行；行内可能多一层反斜杠转义
          if (!cmd.replace(/^\s+/, '').startsWith('/')) {
            errors.push(`clickEvent 命令缺少 / 前缀 于 ${rel}:${lineNo}`);
          }
        }
        // if score / unless score 的比较对象必须是分数持有者：写 `if score A obj < 2` 会整行解析失败
        if (/\b(?:if|unless) score \S+ \S+ *(?:<=|>=|<|>|=) *-?\d/.test(code)) {
          errors.push(`if score 不能直接和数字比较，要用 matches 区间 于 ${rel}:${lineNo}`);
        }
        // matches 形式只收「一个目标 + 一个记分板」：`if score @s ybih.win matches 3..`。
        // 多写一个记分板（顺手把比较形式的两个记分板也带上）是解析错误，
        // 后果与漏 execute 同级：整份函数静默不加载，只往日志写一行 Whilst parsing command。
        if (/\b(?:if|unless) score \S+ \S+ \S+ matches\b/.test(code)) {
          errors.push(`if score 的 matches 形式只收一个目标加一个记分板，多写了一个 于 ${rel}:${lineNo}`);
        }
        // /execute 的条件子命令只有固定那几个，写错名字整行都解析不了。
        // 尤其容易顺手写成 `if team` / `if gamemode` —— 没有这两种条件
        for (const m of code.matchAll(/\b(?:if|unless) ([a-z_]+)/g)) {
          if (!EXECUTE_CONDITIONS.has(m[1])) {
            errors.push(`/execute 没有 if/unless ${m[1]} 这种条件 于 ${rel}:${lineNo}`);
          }
        }
        // at / as / positioned / anchored 这些只是 /execute 的修饰子命令，单独一行
        // 写出来会被当成一条名叫 at（as、positioned…）的命令，整行解析失败。
        // 本条正是为了兜住 button/on_use_trace 那次事故：重构时把一行 execute 拆成
        // 单独的函数，末行漏掉了开头的 execute，只留下 `at @s anchored eyes run ...`。
        // 它让整个函数不加载，而函数加载失败只写进日志、不进聊天栏，
        // 进游戏显示为「按钮有动画有音效，但不加分也没有任何提示」，
        // 与「射线没锁到按钮」的表现一模一样，排查代价极高。构建期拦下最省事。
        // 这些词都没有同名命令，所以行首出现必然是漏了 execute
        const head = code.trimStart();
        const bareExec = head.match(/^(at|as|positioned|anchored|facing|rotated|align|in|on|store|run|if|unless)\s/);
        if (bareExec) {
          errors.push(
            `行首的 ${bareExec[1]} 是 /execute 的修饰子命令，缺少开头的 execute（整行会解析失败、整个函数不加载）于 ${rel}:${lineNo}`,
          );
        }
        // 方块状态里的 face/facing 拼写
        if (
          /\[face=[^,\]]+,/.test(code) &&
          !/face=(floor|ceiling|wall),facing=(north|south|east|west)/.test(code)
        ) {
          errors.push(`方块状态 face/facing 组合可疑 于 ${rel}:${lineNo}`);
        }
        // playsound 的音效 id 直接按名字查表，写错只会静默无声，只能靠白名单兜住
        const soundArgs = commandArgs(code, 'playsound');
        if (soundArgs.length > 0) {
          const id = (soundArgs[0] ?? '').replace(/^minecraft:/, '');
          if (!KNOWN_SOUND_IDS.has(id)) {
            errors.push(`playsound 引用了未登记的音效 ${soundArgs[0]} 于 ${rel}:${lineNo}`);
          }
        }
        // 粒子同理：通道名写错不会报错，只是什么都看不见
        const particleArgs = commandArgs(code, 'particle');
        if (particleArgs.length > 0) {
          const id = (particleArgs[0] ?? '').replace(/^minecraft:/, '');
          if (!KNOWN_PARTICLE_IDS.has(id)) {
            errors.push(`particle 引用了未登记的粒子 ${particleArgs[0]} 于 ${rel}:${lineNo}`);
          }
        }
        // 原版标签引用必须存在，否则整条命令连带整个函数都不加载
        checkVanillaTags(rel, code, errors, true, lineNo, depth);
        // 按版本才有的命令不能出现在低于其引入版本的包里。
        // 这一组留在原文上判定：它们的特征里带版本号 / 参数这类也是字符串形态的东西
        // （例如 limit 用的是记分板），剥掉字符串就会漏检，而句子里的散文命中时
        // 恰好只在「上限早于门槛」的包里有后果 —— 1.16 那条门槛比三个包的下限都低，永远不触发
        for (const gate of VERSION_GATED) {
          if (gate.re.test(line) && !versionAtLeast(pack.minVersion, gate.since)) {
            errors.push(
              `${gate.what} 是 ${gate.since} 起才有的，本包下限 ${pack.minVersion} 用不了 于 ${rel}:${lineNo}`,
            );
          }
        }
      }
    }
  }

  // 收集已定义的函数
  const defined = new Set();
  for (const dirName of ['data/ybih/function', 'data/ybih/functions']) {
    const dir = join(packDir, ...dirName.split('/'));
    if (!existsSync(dir)) continue;
    for (const f of walk(dir)) {
      const rel = relative(dir, f).split(sep).join('/').replace(/\.mcfunction$/, '');
      defined.add(`ybih:${rel}`);
    }
  }
  if (defined.size === 0) errors.push('该包没有任何函数文件');

  // 函数调用引用
  for (const f of files) {
    if (!f.endsWith('.mcfunction')) continue;
    const rel = relative(packDir, f).split(sep).join('/');
    const text = readFileSync(f, 'utf8');
    for (const m of text.matchAll(/\bfunction\s+(ybih:[a-z0-9_/]+)/gi)) {
      if (!defined.has(m[1])) errors.push(`引用不存在的函数 ${m[1]} 于 ${rel}`);
    }
  }

  // 点击通道的值必须有分派。按钮发出 `trigger ybih.trigger set N`，由
  // button/trigger_run 按 N 分派到具体函数 —— 那边漏一条，这个按钮点了就**毫无反应**，
  // 既不报错也不进日志，只能靠玩家发现「这个按钮没用」。真踩过：
  // 【看我的棋盘】(13) 的分派被删掉后，书里和棋盘末尾那个按钮一起变成了死键。
  // 反过来，分派了却没人发的值不算错（可能留给将来的入口），所以只查单向
  {
    const dispatcher = files.find((f) => f.endsWith(`button${sep}trigger_run.mcfunction`));
    if (!dispatcher) {
      errors.push('找不到 button/trigger_run.mcfunction，无法核对点击通道');
    } else {
      const dispText = readFileSync(dispatcher, 'utf8');
      // 只收「真正调了函数」的那些分派行（`... run function ybih:...`）。
      // 不能把文件里所有 `trigger matches` 都当分派 —— trigger_run 末尾还有一条
      // 「matches 11..52」的**提示行**（人不在房里时说一句），它的区间会把 11..52
      // 整个盖住，于是删掉其中任何一个真实分派都检测不出来。
      // 这一版就踩过：13 的分派被删掉后校验依然通过，正是被那条提示行喂了假覆盖
      const ranges = [];
      for (const line of dispText.split(/\r?\n/)) {
        if (!/\brun\s+function\s+ybih:/.test(line)) continue;
        for (const m of line.matchAll(/ybih\.trigger\s+matches\s+(\d+)(?:\.\.(\d+))?/g)) {
          ranges.push([Number(m[1]), m[2] === undefined ? Number(m[1]) : Number(m[2])]);
        }
      }
      const covered = (v) => ranges.some(([lo, hi]) => v >= lo && v <= hi);
      const emitted = new Map(); // 值 → 发出它的文件
      for (const f of files) {
        if (!f.endsWith('.mcfunction')) continue;
        const rel = relative(packDir, f).split(sep).join('/');
        // 分派器自己不算「发出」，避免自我循环
        if (rel.endsWith('button/trigger_run.mcfunction')) continue;
        for (const m of readFileSync(f, 'utf8').matchAll(/ybih\.trigger set (\d+)/g)) {
          const v = Number(m[1]);
          if (!emitted.has(v)) emitted.set(v, rel);
        }
      }
      for (const [v, rel] of [...emitted].sort((a, b) => a[0] - b[0])) {
        if (!covered(v)) {
          errors.push(
            `点击值 ${v} 有按钮在发它（${rel}），但 button/trigger_run 没有分派 —— 按了会毫无反应`,
          );
        }
      }
    }
  }

  // 进度奖励引用的函数。这类引用写错同样只写日志：运行时才报「未知函数」，
  // 表现成「进度触发了但什么也没发生」，比命令里写错更难查 —— 只查 .mcfunction
  // 会把这份引用整片漏掉
  for (const f of files) {
    if (!f.endsWith('.json')) continue;
    const rel = relative(packDir, f).split(sep).join('/');
    let parsed = null;
    try {
      parsed = JSON.parse(readFileSync(f, 'utf8'));
    } catch {
      continue; // JSON 非法已在上面报过
    }
    const targets = [
      ['rewards.function', parsed?.rewards?.function],
      ['rewards.functions', parsed?.rewards?.functions],
    ];
    for (const [where, value] of targets) {
      // rewards.function 是单个字符串，rewards.functions 是字符串数组，两种都收
      for (const v of Array.isArray(value) ? value : [value]) {
        if (typeof v !== 'string' || !v.startsWith('ybih:')) continue;
        if (!defined.has(v)) errors.push(`${where} 引用了不存在的函数 ${v} 于 ${rel}`);
      }
    }
  }

  // 函数标签引用
  for (const tagName of ['load', 'tick']) {
    for (const dirName of ['data/minecraft/tags/function', 'data/minecraft/tags/functions']) {
      const p = join(packDir, ...dirName.split('/'), `${tagName}.json`);
      if (!existsSync(p)) continue;
      const json = JSON.parse(readFileSync(p, 'utf8'));
      for (const v of json.values ?? []) {
        if (typeof v === 'string' && v.startsWith('ybih:') && !defined.has(v)) {
          errors.push(`函数标签 ${tagName}.json 引用了不存在的函数 ${v}`);
        }
      }
    }
  }

  // 按钮清单自洽性：每个材质都要出现在按下分派与取消重放的生成结果里
  const readFunc = (rel) => {
    for (const prefix of ['data/ybih/function/', 'data/ybih/functions/']) {
      const p = join(packDir, ...(prefix + rel).split('/'));
      if (existsSync(p)) return readFileSync(p, 'utf8');
    }
    return '';
  };
  for (const m of pack.materials) {
    const tag = MATERIAL_TO_TAG(m);
    for (const [file, label] of [
      ['button/press_scan.mcfunction', 'press_scan'],
      ['button/protect_restore.mcfunction', 'protect_restore'],
      ['button/refund_pending.mcfunction', 'refund_pending'],
    ]) {
      if (!readFunc(file).includes(tag)) errors.push(`按钮 ${m} 未出现在 ${label} 中`);
    }
  }

  // 可放置白名单：引用了该包版本区间里还不存在的方块时，整个标签会加载失败，
  // 冒险模式下玩家一个按钮都放不下去，而构建期毫无提示 —— 必须在这里拦住。
  // 同时 1.16 / 1.16.1 不认 {"id":...,"required":false} 的对象条目，只接受字符串。
  for (const rel of ['tags/block/placeable_surfaces.json', 'tags/blocks/placeable_surfaces.json']) {
    const p = join(packDir, 'data/ybih', ...rel.split('/'));
    if (!existsSync(p)) continue;
    let parsed;
    try {
      parsed = JSON.parse(readFileSync(p, 'utf8'));
    } catch {
      continue; // JSON 非法已由上面的通用校验报出
    }
    for (const entry of parsed.values ?? []) {
      const isObject = typeof entry === 'object' && entry !== null;
      const id = isObject ? entry.id : entry;
      if (typeof id !== 'string') {
        errors.push(`白名单条目格式可疑：${JSON.stringify(entry)} 于 ${rel}`);
        continue;
      }
      if (!id.startsWith('#')) {
        const since = sinceOf(id);
        // 查不到 = 忘了登记。不能默认放行：生成过滤器用的是同一个默认值，
        // 两边同源就永远查不出来，1.17+ 的新方块会静默进到面向 1.16.2 的包 1 里
        if (since === null) {
          errors.push(
            `白名单里的方块 ${id} 不在 src/block_versions.mjs 的 BLOCK_SINCE 里，` +
              `请先登记它从哪个版本开始存在（${rel}）`,
          );
        } else if (!versionAtLeast(pack.minVersion, since)) {
          errors.push(
            `白名单引用了 ${pack.minVersion} 还不存在的方块 ${id}（${since} 起加入）于 ${rel}`,
          );
        }
      }
    }
  }

  // 「需要支撑」的方块不能往空气里铺：地毯、花草、铁轨这类方块下面没有实心方块时
  // 会被瞬间崩掉，而 fill 依然报「成功」、函数也不报错，方块却一个不剩。
  // 等待室是悬在天上的，一旦地板换成这类方块而忘了垫层，整间房就没地板，
  // turn/gather 的守卫也永远过不去（等待者只留在集合点，且毫无提示）。
  // 这条校验只覆盖等待室：它是本包里唯一一处「悬空铺装饰方块」的地方
  const NEEDS_SUPPORT = /(?:carpet|_rail|_sapling|flower_pot|sunflower|dandelion|poppy|torch)$/;
  const roomLines = readFunc('util/build_wait_room.mcfunction').split('\n');
  // fill 的坐标形如 ~-6 ~-1 ~-6 ~6 ~-1 ~6：两端 y 都必须是 ~-1，才算是地板垫层
  const isFoundationFill = (line) => {
    if (!/\brun fill\b/.test(line)) return false;
    const m = line.match(/\brun fill\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s/);
    if (!m) return false;
    return m[2] === '~-1' && m[5] === '~-1';
  };
  const firstDecor = roomLines.findIndex((l) => /\brun fill\b/.test(l) && NEEDS_SUPPORT.test(l.trim()));
  if (firstDecor !== -1) {
    const foundation = roomLines.findIndex((l, i) => i < firstDecor && isFoundationFill(l));
    if (foundation === -1) {
      errors.push(
        '等待室地板用了「需要支撑」的方块（如地毯），但基准层下面没有垫层：' +
          '悬空铺地毯会被瞬间崩掉，fill 仍报成功，整间房会没有地板。' +
          '请在铺地毯之前先 fill 一层 y=~-1 的实心方块（见 util/build_wait_room）',
      );
    }
  }

  // 拆等待室要分两条、且地基那条在最后：fill 内部自下而上执行，一条 ~-1..~8 会先抽掉
  // 地毯的地基，地毯随之崩成掉落物（实测 69 个）从 245 的高空摔到地面。
  // 这条守卫盯的是「同一条 fill 同时覆盖 ~-1 与基准层及以上」
  const rmLines = readFunc('util/remove_wait_room.mcfunction').split('\n');
  const yRange = (line) => {
    const m = line.match(/\brun fill\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+\S+\s/);
    return m ? [m[1], m[2]] : null;
  };
  for (const line of rmLines) {
    const r = yRange(line);
    if (!r) continue;
    if (r[0] === '~-1' && /^~\d/.test(r[1])) {
      errors.push(
        'util/remove_wait_room 用一条 fill 同时拆了地毯地基（~-1）与基准层及以上：' +
          'fill 内部自下而上，会先抽掉地基，地毯当场崩成掉落物掉一地。' +
          '请拆成两条，先 fill ~..~8 收地毯与房子，最后再单独收 ~-1 的地基',
      );
    }
  }

  // Boss 栏进度条要覆盖 0–100 每一个整数档，缺档会让进度条卡住不动
  const barSteps = readFunc('game/bar_value.mcfunction')
    .split('\n')
    .filter((line) => line.includes('bossbar set ybih:timer value'));
  if (barSteps.length !== 101) {
    errors.push(`Boss 栏进度条应有 101 个档位，实际 ${barSteps.length} 个`);
  }
  for (let i = 0; i <= 100; i++) {
    if (!barSteps.some((line) => line.endsWith(`value ${i}`))) {
      errors.push(`Boss 栏进度条缺少 ${i} 档`);
    }
  }

  return errors;
}

// ── 主流程 ───────────────────────────────────────────────────────

// 设置书自洽性：跳页链接要落在有效页面，页脚要落在最后一行，任何一行都不能折行
function validateBook() {
  const errors = [];
  const total = BOOK_PAGES.length;
  if (!HINT_RADII.includes(HINT_RANGE_DEFAULT)) {
    errors.push(`提示半径的默认档 ${HINT_RANGE_DEFAULT} 不在 HINT_RADII 档位表里`);
  }
  // 目录页固定在第 1 页（footerRow 也按 index === 0 认它）。它必须把第 2 页起的每一页
  // 都列到，不重不漏，而且前面的「N页」与实际指向一致 —— 页码是手写的，
  // 只查越界查不出「指到了隔壁那一页」这种错
  const toc = BOOK_PAGES[0];
  const listed = toc.items.filter((it) => it.page !== undefined).map((it) => it.page);
  const want = Array.from({ length: total - 1 }, (_, i) => i + 2);
  const missing = want.filter((p) => !listed.includes(p));
  const dup = [...new Set(listed.filter((p, i) => listed.indexOf(p) !== i))];
  if (missing.length > 0) errors.push(`目录页漏了第 ${missing.join('、')} 页的入口`);
  if (dup.length > 0) errors.push(`目录页把第 ${dup.join('、')} 页列了不止一次`);
  for (const item of toc.items) {
    if (item.page === undefined) continue;
    if (item.prefix !== `${item.page}页　`) {
      errors.push(`目录页「${item.label}」前面写的是「${String(item.prefix).trim()}」，可它指向第 ${item.page} 页`);
    }
  }
  // 两本书共用同一套版式尺子：设置书与等待室那本《九宫格棋》
  errors.push(...validatePages(BOOK_PAGES, '设置书'));
  errors.push(...validatePages(TTT_BOOK_PAGES, '九宫格棋书'));
  return errors;
}

// 逐页体检：行数、折行宽度、字符量、排出来的总行数。两本书共用同一把尺子
function validatePages(pages, bookName) {
  const errors = [];
  const total = pages.length;
  pages.forEach((page, index) => {
    const where = `${bookName}第 ${index + 1} 页「${page.title}」`;
    for (const item of page.items) {
      if (item.page !== undefined && (item.page < 1 || item.page > total)) {
        errors.push(`${where}的「${item.label}」跳到不存在的第 ${item.page} 页`);
      }
    }
    const rows = pageContentRows(page);
    const limit = BOOK_LINES - 2;
    if (rows.length > limit) {
      errors.push(`${where}内容 ${rows.length} 行，最多只能放 ${limit} 行，页脚会被顶出页面`);
    }
    rows.forEach((row, i) => {
      const text = row.map((part) => part.text).join('');
      const width = textWidth(text);
      if (width > BOOK_LINE_WIDTH) {
        errors.push(`${where}第 ${i + 1} 行宽约 ${width} 像素（上限 ${BOOK_LINE_WIDTH}）会折行：${text}`);
      }
    });
    const chars = rows.reduce((sum, row) => sum + row.reduce((n, part) => n + part.text.length, 0) + 1, 0);
    if (chars > 250) {
      errors.push(`${where}共 ${chars} 个字符，接近单页字符上限，建议拆成两页`);
    }
    const lines = pageLines(page, index, total);
    if (lines.length > BOOK_LINES) {
      errors.push(`${where}排出来 ${lines.length} 行，超出一页 ${BOOK_LINES} 行的容量`);
    }
  });
  return errors;
}

// ---- ZIP 打包（手写结构，不引第三方依赖）----

// ZIP 用 CRC-32 校验每个条目，Node 没有现成 API，这里查表实现
const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();

function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

// 把目录打成 zip。条目路径相对目录本身，所以 pack.mcmeta 落在压缩包根部，
// 游戏才认得出这是数据包（多套一层目录就读不到）
// 目录条目必须"先于其内容"写入，否则解压器遇到 data/minecraft/xxx 时父目录还不存在
function zipDir(dir, zipPath) {
  const entries = [];
  const addDir = (abs, rel) => {
    const names = readdirSync(abs).sort();
    for (const name of names) {
      const full = join(abs, name);
      if (statSync(full).isDirectory()) {
        const r = `${rel}${name}/`;
        entries.push({ name: r, data: null }); // 先记目录本身
        addDir(full, r); // 再递归其内容
      } else {
        const rawBytes = readFileSync(full);
        // ZIP 的 method 8 要的是裸 deflate 流；deflateSync 会加 zlib 头尾，解压器读不了。
        // crc 必须按**未压缩**原字节算，usize 也记的是原长度
        entries.push({
          name: `${rel}${name}`,
          data: deflateRawSync(rawBytes),
          usize: rawBytes.length,
          crc: crc32(rawBytes),
        });
      }
    }
  };
  addDir(dir, '');

  const chunks = [];
  const central = [];
  let offset = 0;

  for (const e of entries) {
    const nameBuf = Buffer.from(e.name, 'utf8');
    const isDir = e.data === null;
    const comp = isDir ? Buffer.alloc(0) : e.data; // deflate 后的字节
    const usize = isDir ? 0 : e.usize; // 未压缩长度
    const crc = isDir ? 0 : e.crc; // 未压缩数据的校验值
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4); // 解压所需版本
    local.writeUInt16LE(0x0800, 6); // bit 11：文件名按 UTF-8 解
    local.writeUInt16LE(8, 8); // deflate
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(comp.length, 18); // 压缩后大小
    local.writeUInt32LE(usize, 22); // 未压缩大小
    local.writeUInt16LE(nameBuf.length, 26);
    chunks.push(local, nameBuf, comp);

    const cd = Buffer.alloc(46);
    cd.writeUInt32LE(0x02014b50, 0);
    cd.writeUInt16LE(20, 4);
    cd.writeUInt16LE(20, 6);
    cd.writeUInt16LE(0x0800, 8);
    cd.writeUInt16LE(8, 10);
    cd.writeUInt32LE(crc, 16);
    cd.writeUInt32LE(comp.length, 20);
    cd.writeUInt32LE(usize, 24);
    cd.writeUInt16LE(nameBuf.length, 28);
    cd.writeUInt32LE(offset, 42);
    central.push(cd, nameBuf);

    offset += local.length + nameBuf.length + comp.length;
  }

  const cdBuf = Buffer.concat(central);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8);
  end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(cdBuf.length, 12);
  end.writeUInt32LE(offset, 16);
  writeFileSync(zipPath, Buffer.concat([...chunks, cdBuf, end]));
  return entries.length;
}

// 清掉 dist/ 下不属于当前包的残留。
// 改过包 id（改名、拆并包）之后旧文件会一直留着，带着上一版的包名与内容，
// 很容易被当成新产物部署出去。dist/ 最终只该有 PACKS 里那几个 .zip，
// 所以这里按「不在预期名单里就删」处理，目录与旧 zip 一并清掉
function pruneStale() {
  if (!existsSync(DIST)) return [];
  const alive = new Set(PACKS.map((p) => `${p.id}.zip`));
  const removed = [];
  for (const name of readdirSync(DIST)) {
    if (alive.has(name)) continue;
    rmSync(join(DIST, name), { recursive: true, force: true });
    removed.push(name);
  }
  return removed;
}

let failed = false;
console.log('构建 ybih 数据包\n');

// 先清残留：dist/ 里只应存在 PACKS 对应的 .zip，
// 其余的（旧包目录、改过名的旧 zip、上次构建中断留下的暂存目录）一律删掉
const pruned = pruneStale();
if (pruned.length > 0) {
  console.log(`  · 已清理 ${pruned.length} 项不再产出的残留：${pruned.join('、')}\n`);
}

// 棋盘三格必须等宽：聊天栏没有制表位，每行靠「三种格子占一样宽」才能对齐成九宫格。
// 曾经把落子画成单个 ✕（9 像素）而空格画成【1】（24 像素），同一行里宽度不等，
// 一落子整行就跟着缩，列全歪 —— 实测错位就是这么来的。
// 这条校验直接把「等宽」钉成硬约束：以后谁改了 TTT_X / TTT_O / TTT_SP / BTN_TTT_*，
// 只要三者宽度不再一致，构建当场失败
function validateBoardCells() {
  const errors = [];
  const extract = (raw) => {
    const m = raw.match(/(?:"text"|text)\s*:\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)')/);
    return m ? (m[1] ?? m[2] ?? '') : null;
  };
  const cells = [
    ['空格（可点）', TEXT_JSON.BTN_TTT_1],
    ['叉', TEXT_JSON.TTT_X],
    ['圈', TEXT_JSON.TTT_O],
  ];
  const widths = [];
  for (const [name, raw] of cells) {
    const text = extract(raw ?? '');
    if (text === null) {
      errors.push(`棋盘记号「${name}」里找不到 text 字段，无法核对宽度`);
      continue;
    }
    widths.push([name, text, textWidth(text)]);
  }
  if (widths.length === 3) {
    const base = widths[0][2];
    for (const [name, text, w] of widths) {
      if (w !== base) {
        errors.push(
          `棋盘三格不等宽：${widths[0][0]}「${widths[0][1]}」${base} 像素，` +
            `但${name}「${text}」${w} 像素 —— 聊天栏没有制表位，宽度不等会让棋盘错位`,
        );
      }
    }
    // 九个落子按钮彼此也要一样宽（都是「【全角数字】」）
    for (let n = 1; n <= 9; n += 1) {
      const text = extract(TEXT_JSON[`BTN_TTT_${n}`] ?? '');
      if (text === null) {
        errors.push(`棋盘第 ${n} 格的可点按钮里找不到 text 字段`);
      } else if (textWidth(text) !== base) {
        errors.push(
          `棋盘第 ${n} 格「${text}」宽 ${textWidth(text)} 像素，与其余格子（${base} 像素）不一致`,
        );
      }
    }
  }
  return errors;
}

const bookErrors = validateBook();
const boardErrors = validateBoardCells();
if (boardErrors.length > 0) {
  failed = true;
  console.log('  ✗ 棋盘格子对齐');
  for (const e of boardErrors) console.log(`      - ${e}`);
  console.log('');
}
if (bookErrors.length > 0) {
  failed = true;
  console.log('  ✗ 设置书排版');
  for (const e of bookErrors) console.log(`      - ${e}`);
  console.log('');
}

for (const pack of PACKS) {
  // 先构建到暂存目录，打包成 zip 后再删掉它 —— dist/ 最终只留 zip
  const dir = buildPack(pack);
  const errors = validate(dir, pack);
  const count = walk(dir).length;

  if (errors.length === 0) {
    // 校验通过才打包，避免把有问题的产物封进 zip 发出去
    const zipPath = join(DIST, `${pack.id}.zip`);
    const n = zipDir(dir, zipPath);
    rmSync(dir, { recursive: true, force: true });
    const kb = (statSync(zipPath).size / 1024).toFixed(0);
    console.log(
      `  ✓ ${pack.id}  ${pack.label}  ${count} 个文件  按钮 ${pack.materials.length} 种  → ${pack.id}.zip（${n} 条目 / ${kb} KB）`,
    );
  } else {
    failed = true;
    rmSync(dir, { recursive: true, force: true });
    // 校验不通过的包不留下任何产物：只删暂存目录的话，dist/ 里会留着上一代同名 zip，
    // 而它看起来和别的新产物一模一样 —— 人工扫一眼 dist/ 会以为三个包都构建成功了。
    // 只删自己这一份，另外两个构建成功的包照常保留
    const zipPath = join(DIST, `${pack.id}.zip`);
    const hadStaleZip = existsSync(zipPath);
    rmSync(zipPath, { force: true });
    console.log(`  ✗ ${pack.id}  ${pack.label}  ${count} 个文件`);
    for (const e of errors) console.log(`      - ${e}`);
    console.log(
      hadStaleZip
        ? `      → ${pack.id}.zip 是上一次构建的旧产物，已一并删除`
        : `      → 本包没有产出 ${pack.id}.zip`,
    );
  }
}

console.log('');
if (failed) {
  console.log('构建完成，但存在校验错误。');
  process.exitCode = 1;
} else {
  console.log('构建完成，全部校验通过。');
  console.log('产物是 dist/ 下的 .zip，整个复制进存档的 datapacks/ 即可（不要解压）。');
}
