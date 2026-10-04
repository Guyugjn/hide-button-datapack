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
  SETTING_FUNCS,
  BUTTON_FACINGS,
  BOOK_PAGES,
  BOOK_LINES,
  BOOK_LINE_WIDTH,
  HINT_RADII,
  HINT_RANGE_DEFAULT,
  pageContentRows,
  pageLines,
  textWidth,
} from '../src/manifest.mjs';
import { BLOCK_SINCE, versionAtLeast } from '../src/block_versions.mjs';

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
  const lines = ['# ybih:player/give_buttons —— 发放按钮（每种材质一个）', ''];
  for (const m of pack.materials) lines.push(`give @s ${pack.give(m)} 1`);
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
function genProtectCheck(pack) {
  const scan =
    'execute as @e[type=armor_stand,tag=ybih_button,tag=!ybih_pending] if score @s ybih.era = #era ybih.config at @s';
  return [
    '# ybih:button/protect_check —— 位置上没有按钮的才交给 protect_restore（只处理本局登记的标记）',
    '# 同一位置反复被破坏说明它保不住，数到上限就收回它，免得一直复制按钮物品',
    '',
    `${scan} unless block ~ ~ ~ #minecraft:buttons run scoreboard players add @s ybih.fixed 1`,
    `${scan} if score @s ybih.fixed matches ..3 unless block ~ ~ ~ #minecraft:buttons run function ybih:button/protect_restore`,
    `${scan} if score @s ybih.fixed matches 4.. unless block ~ ~ ~ #minecraft:buttons run function ybih:button/give_up`,
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
    '# ybih:game/showcase_view —— 把参与者放进按钮那一格，视线对准按钮面板',
    '# 执行者是待展示按钮的标记实体：位置一律本格中心，只有朝向分派视线角度',
    '# 传送目标限定参与者：与 showcase_end 的清理口径保持一致，',
    '# 否则围观期间重连或中途进服的人会被拖到展示点，却不在任何清理与恢复的范围内',
    '',
  ];
  const tags = [];
  for (const f of BUTTON_FACINGS) {
    const [yaw, pitch] = SHOWCASE_AIMS[showcaseKey(f.tag)];
    lines.push(
      `execute if entity @s[tag=${f.tag}] at @s run tp @a[tag=ybih_player] ~ ~-1 ~ ${yaw} ${pitch}`,
    );
    tags.push(f.tag);
  }
  // 十二条朝向一条都没命中的标记（朝向标签被外部命令破坏或丢失）不能让围观空转：
  // 照原样原地待着，至少标题和 Boss 栏照常报进度。这条兜底不带位置偏移，
  // 因为它本来就不确定站在哪，硬挪反而可能把人塞进地形里
  const noneMatched = tags.map((t) => `unless entity @s[tag=${t}]`).join(' ');
  lines.push(`execute at @s ${noneMatched} run tp @a[tag=ybih_player] ~ ~ ~`);
  return lines.join('\n') + '\n';
}

// 传送后的定格：玩家还按着方向键、客户端又已经按旧速度预测了位移，
// 刚被 tp 到新位置就会顺着原来的方向飞出去。定格期间每 tick 把所有人拉回同一个位置，
// 把输入造成的那一段位移压掉。
// 只用位置参数、**不带角度** —— 带上角度会连玩家的视角一起锁死，转不了头看周围。
function genShowcasePin(pack) {
  const lines = [
    '# ybih:game/showcase_pin —— 定格期间把参与者按回站位，只设位置、不设角度',
    '# 执行者是待展示按钮的标记实体；玩家在定格期间仍然可以自由转视角',
    '# 传送目标与 showcase_view 一致，只作用于参与者',
    '',
  ];
  const tags = [];
  for (const f of BUTTON_FACINGS) {
    lines.push(`execute if entity @s[tag=${f.tag}] at @s run tp @a[tag=ybih_player] ~ ~-1 ~`);
    tags.push(f.tag);
  }
  // 与 showcase_view 同样的兜底：一条朝向都没命中时留在原地，不硬挪
  const noneMatched = tags.map((t) => `unless entity @s[tag=${t}]`).join(' ');
  lines.push(`execute at @s ${noneMatched} run tp @a[tag=ybih_player] ~ ~ ~`);
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
    if (!id.startsWith('#')) {
      const since = BLOCK_SINCE[id] ?? '1.16';
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

const GENERATED = {
  'data/ybih/function/player/give_buttons.mcfunction': genGiveButtons,
  'data/ybih/function/button/tag_material.mcfunction': genTagMaterial,
  'data/ybih/function/button/tag_face.mcfunction': genTagFace,
  'data/ybih/function/button/press_tick.mcfunction': genPressTick,
  'data/ybih/function/button/press_scan.mcfunction': genPressScan,
  'data/ybih/function/button/hit_bit.mcfunction': genHitBit,
  'data/ybih/function/button/protect_check.mcfunction': genProtectCheck,
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
function findBadEscapes(line, snbt) {
  const extra = snbt ? ['n', 't', 'b', 'f', 'r', 'x', 'u'] : [];
  const bad = [];
  for (const quote of ['"', "'"]) {
    let i = 0;
    while (i < line.length) {
      if (line[i] !== quote) {
        i++;
        continue;
      }
      let j = i + 1;
      while (j < line.length && line[j] !== quote) {
        if (line[j] === '\\') {
          const next = line[j + 1];
          if (next !== quote && next !== '\\' && !extra.includes(next)) bad.push(`\\${next}`);
          j += 2;
          continue;
        }
        j++;
      }
      i = j + 1;
    }
  }
  return bad;
}

// 按版本才有的命令与子命令。用在低于其引入版本的包里会让整行解析失败，
// 而函数加载失败只写进日志、不进聊天栏，进游戏只会看到「什么都没发生」。
// 键是命令特征的匹配式，值是它开始存在的版本。
const VERSION_GATED = [
  { re: /\brun return\b|^\s*return\b/, since: '1.20.2', what: '/return' },
  { re: /\bexecute\s+if\s+items\b/, since: '1.20.5', what: 'execute if items' },
  { re: /\bexecute\s+if\s+loaded\b/, since: '1.20.5', what: 'execute if loaded' },
  { re: /\bexecute\s+if\s+stopwatch\b/, since: '1.21.5', what: 'execute if stopwatch' },
  { re: /\bexecute\s+if\s+biome\b/, since: '1.19.4', what: 'execute if biome' },
  { re: /\bexecute\s+if\s+dimension\b/, since: '1.19', what: 'execute if dimension' },
  { re: /\bdata\s+modify\b/, since: '1.20.2', what: '/data modify' },
  { re: /\brandom\s+value\b/, since: '1.20.2', what: '/random' },
  { re: /@[aespr]\w*\[[^\]]*\blimit\s*=/, since: '1.16', what: '选择器 limit 参数' },
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
      // 判定按包的下限走，而不是按「看起来像什么」——否则两种写法都像对的
      const legacyLocOk = !versionAtLeast(pack.minVersion, '1.20');
      if (parsed && rel.includes('advancement')) {
        for (const [name, crit] of Object.entries(parsed.criteria ?? {})) {
          const loc = crit?.conditions?.location;
          if (loc === undefined) continue;
          if (!Array.isArray(loc)) {
            if (
              legacyLocOk &&
              typeof loc === 'object' &&
              loc !== null &&
              loc.block !== undefined
            ) {
              continue; // 1.20 之前的合法写法
            }
            errors.push(
              `进度条件 location 必须是谓词数组（写成裸对象会导致条件永不匹配）于 ${rel} 的 ${name}`,
            );
            continue;
          }
          for (const [i, entry] of loc.entries()) {
            if (typeof entry !== 'object' || entry === null || typeof entry.condition !== 'string') {
              errors.push(`进度条件 location[${i}] 缺少 condition 字段于 ${rel} 的 ${name}`);
            }
          }
        }
      }
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
        if (/forceload\s+add\s+~\s+~\s+~/.test(line)) {
          errors.push(`forceload 参数过多（只要 x z 两个坐标）于 ${rel}:${lineNo}`);
        }
        // 点击执行的命令必须带 / 前缀，否则客户端拒绝执行
        // 只查 run_command 自己的那个字段，change_page 的 value 是页号，不能混进来
        for (const m of line.matchAll(/"action":"run_command","value":"([^"]*)"/g)) {
          if (!m[1].startsWith('/')) {
            errors.push(`clickEvent 命令缺少 / 前缀 于 ${rel}:${lineNo}`);
          }
        }
        for (const m of line.matchAll(/action:'run_command',command:'([^']*)'/g)) {
          if (!m[1].startsWith('/')) {
            errors.push(`clickEvent 命令缺少 / 前缀 于 ${rel}:${lineNo}`);
          }
        }
        // if score / unless score 的比较对象必须是分数持有者：写 `if score A obj < 2` 会整行解析失败
        if (/\b(?:if|unless) score \S+ \S+ *(?:<=|>=|<|>|=) *-?\d/.test(line)) {
          errors.push(`if score 不能直接和数字比较，要用 matches 区间 于 ${rel}:${lineNo}`);
        }
        // /execute 的条件子命令只有固定那几个，写错名字整行都解析不了。
        // 尤其容易顺手写成 `if team` / `if gamemode` —— 没有这两种条件
        for (const m of line.matchAll(/\b(?:if|unless) ([a-z_]+)/g)) {
          if (!EXECUTE_CONDITIONS.has(m[1])) {
            errors.push(`/execute 没有 if/unless ${m[1]} 这种条件 于 ${rel}:${lineNo}`);
          }
        }
        // 方块状态里的 face/facing 拼写
        if (/\[face=[^,\]]+,/.test(line) && !/face=(floor|ceiling|wall),facing=(north|south|east|west)/.test(line)) {
          errors.push(`方块状态 face/facing 组合可疑 于 ${rel}:${lineNo}`);
        }
        // 原版标签引用必须存在，否则整条命令连带整个函数都不加载
        for (const m of line.matchAll(/#(minecraft:[a-z0-9_/]+)/g)) {
          if (!KNOWN_VANILLA_TAGS.has(m[1].slice('minecraft:'.length))) {
            errors.push(`引用了未登记的原版标签 #${m[1]} 于 ${rel}:${lineNo}`);
          }
        }
        // 按版本才有的命令不能出现在低于其引入版本的包里
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
        const since = BLOCK_SINCE[id] ?? '1.16';
        if (!versionAtLeast(pack.minVersion, since)) {
          errors.push(
            `白名单引用了 ${pack.minVersion} 还不存在的方块 ${id}（${since} 起加入）于 ${rel}`,
          );
        }
      }
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
  BOOK_PAGES.forEach((page, index) => {
    const where = `第 ${index + 1} 页「${page.title}」`;
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

const bookErrors = validateBook();
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
    console.log(`  ✗ ${pack.id}  ${pack.label}  ${count} 个文件`);
    for (const e of errors) console.log(`      - ${e}`);
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
