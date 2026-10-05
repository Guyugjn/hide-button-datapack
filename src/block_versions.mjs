// 方块 ID 的加入版本表：构建时据此过滤 placeable_surfaces，并为校验提供依据。
//
// **这是一张全量表，不是例外表**：进入 placeable_surfaces 的每一个方块都必须在
// 这里查得到。查不到 = 忘了登记，构建会直接报错并说明该登记什么，
// 而不是当成「1.16 起就有」静默放行。
//
// 曾经的做法是「只登记跨版本会踩坑的方块，未登记的按 1.16 起就有处理」，
// 而生成过滤器与校验器用的是同一个默认值 —— 两边同源，谁都查不出来：
// 1.17 之后加入却忘了登记的方块会照样进包 1，而包 1 的下限是 1.16.2，
// 引用该版本还不存在的方块会让**整个标签加载失败**，冒险模式下一个按钮都放不下去。
// 现在两个默认值刻意拆开：生成期「查不到就照写」，校验期「查不到就报错」。
//
// 数据来源：
//   1.16.5 客户端 jar 的 assets/minecraft/blockstates/ 全量清单（764 项，作为 1.16 基准）
//   1.17 / 1.19 / 1.20 的官方更新日志与 wiki 版本页
//
// 版本号写成数字，比较时按 (主, 次) 处理：1.16 < 1.16.2 < 1.17 < 1.20 < 1.20.5 < 1.21

export const BLOCK_SINCE = {
  // ── 1.16 基准 ──────────────────────────────────────────────────
  // 下面这批是白名单里一直用到、且 1.16.2 就存在的方块。
  // 它们以前靠「未登记 = 1.16」的默认值隐式放行，现在显式登记：
  // 行为完全不变，但省略登记不再是一条静默通道。
  'minecraft:dirt': '1.16',
  'minecraft:grass_block': '1.16',
  'minecraft:podzol': '1.16',
  'minecraft:coarse_dirt': '1.16',
  'minecraft:farmland': '1.16',
  'minecraft:mycelium': '1.16',
  'minecraft:sand': '1.16',
  'minecraft:red_sand': '1.16',
  'minecraft:gravel': '1.16',
  'minecraft:clay': '1.16',
  'minecraft:soul_sand': '1.16',
  'minecraft:soul_soil': '1.16',
  'minecraft:snow_block': '1.16',
  'minecraft:ice': '1.16',
  'minecraft:packed_ice': '1.16',
  'minecraft:blue_ice': '1.16',
  'minecraft:stone': '1.16',
  'minecraft:cobblestone': '1.16',
  'minecraft:mossy_cobblestone': '1.16',
  'minecraft:granite': '1.16',
  'minecraft:diorite': '1.16',
  'minecraft:andesite': '1.16',
  'minecraft:sandstone': '1.16',
  'minecraft:red_sandstone': '1.16',
  'minecraft:bricks': '1.16',
  'minecraft:stone_bricks': '1.16',
  'minecraft:mossy_stone_bricks': '1.16',
  'minecraft:netherrack': '1.16',
  'minecraft:nether_bricks': '1.16',
  'minecraft:blackstone': '1.16',
  'minecraft:basalt': '1.16',
  'minecraft:end_stone': '1.16',
  'minecraft:purpur_block': '1.16',
  'minecraft:prismarine': '1.16',
  'minecraft:obsidian': '1.16',
  'minecraft:terracotta': '1.16',
  'minecraft:glass': '1.16',
  'minecraft:glowstone': '1.16',
  'minecraft:sea_lantern': '1.16',
  'minecraft:oak_planks': '1.16',
  'minecraft:spruce_planks': '1.16',
  'minecraft:birch_planks': '1.16',
  'minecraft:jungle_planks': '1.16',
  'minecraft:acacia_planks': '1.16',
  'minecraft:dark_oak_planks': '1.16',
  'minecraft:crimson_planks': '1.16',
  'minecraft:warped_planks': '1.16',
  'minecraft:oak_log': '1.16',
  'minecraft:spruce_log': '1.16',
  'minecraft:birch_log': '1.16',
  'minecraft:jungle_log': '1.16',
  'minecraft:acacia_log': '1.16',
  'minecraft:dark_oak_log': '1.16',
  'minecraft:oak_leaves': '1.16',
  'minecraft:spruce_leaves': '1.16',
  'minecraft:birch_leaves': '1.16',
  'minecraft:jungle_leaves': '1.16',
  'minecraft:acacia_leaves': '1.16',
  'minecraft:dark_oak_leaves': '1.16',
  'minecraft:white_wool': '1.16',
  'minecraft:orange_wool': '1.16',
  'minecraft:magenta_wool': '1.16',
  'minecraft:light_blue_wool': '1.16',
  'minecraft:yellow_wool': '1.16',
  'minecraft:lime_wool': '1.16',
  'minecraft:pink_wool': '1.16',
  'minecraft:gray_wool': '1.16',
  'minecraft:light_gray_wool': '1.16',
  'minecraft:cyan_wool': '1.16',
  'minecraft:purple_wool': '1.16',
  'minecraft:blue_wool': '1.16',
  'minecraft:brown_wool': '1.16',
  'minecraft:green_wool': '1.16',
  'minecraft:red_wool': '1.16',
  'minecraft:black_wool': '1.16',
  'minecraft:white_concrete': '1.16',
  'minecraft:gray_concrete': '1.16',
  'minecraft:black_concrete': '1.16',
  'minecraft:bookshelf': '1.16',
  'minecraft:furnace': '1.16',
  'minecraft:hay_block': '1.16',
  'minecraft:iron_block': '1.16',
  'minecraft:gold_block': '1.16',
  'minecraft:diamond_block': '1.16',
  'minecraft:emerald_block': '1.16',
  'minecraft:coal_block': '1.16',
  'minecraft:quartz_block': '1.16',
  'minecraft:smooth_stone': '1.16',
  'minecraft:honeycomb_block': '1.16',
  'minecraft:crafting_table': '1.16',

  // ── 1.17 洞穴与山崖 ────────────────────────────────────────────
  'minecraft:rooted_dirt': '1.17',
  'minecraft:dirt_path': '1.17',
  'minecraft:moss_block': '1.17',
  'minecraft:moss_carpet': '1.17',
  'minecraft:deepslate': '1.17',
  'minecraft:cobbled_deepslate': '1.17',
  'minecraft:tuff': '1.17',
  'minecraft:calcite': '1.17',
  'minecraft:dripstone_block': '1.17',
  'minecraft:glow_lichen': '1.17',
  'minecraft:azalea_leaves': '1.17',
  'minecraft:flowering_azalea_leaves': '1.17',
  'minecraft:amethyst_block': '1.17',
  'minecraft:copper_block': '1.17',
  'minecraft:raw_iron_block': '1.17',
  'minecraft:raw_copper_block': '1.17',
  'minecraft:raw_gold_block': '1.17',
  'minecraft:smooth_basalt': '1.17',
  'minecraft:infested_deepslate': '1.17',

  // ── 1.19 荒野更新 ──────────────────────────────────────────────
  'minecraft:mangrove_planks': '1.19',
  'minecraft:mangrove_log': '1.19',
  'minecraft:mangrove_leaves': '1.19',
  'minecraft:mud': '1.19',
  'minecraft:mud_bricks': '1.19',
  'minecraft:muddy_mangrove_roots': '1.19',
  'minecraft:packed_mud': '1.19',
  'minecraft:sculk': '1.19',

  // ── 1.20 轨迹与故事 ────────────────────────────────────────────
  'minecraft:bamboo_planks': '1.20',
  'minecraft:bamboo_mosaic': '1.20',
  'minecraft:cherry_planks': '1.20',
  'minecraft:cherry_log': '1.20',
  'minecraft:cherry_leaves': '1.20',
  'minecraft:stripped_cherry_log': '1.20',
  'minecraft:chiseled_bookshelf': '1.20',

  // ── 1.21 ──────────────────────────────────────────────────────
  'minecraft:tuff_bricks': '1.21',
  'minecraft:chiseled_tuff': '1.21',
  'minecraft:polished_tuff': '1.21',
  'minecraft:copper_bulb': '1.21',
  'minecraft:copper_grate': '1.21',
  'minecraft:chiseled_copper': '1.21',

  // ── 1.21.4 苍园 ────────────────────────────────────────────────
  'minecraft:pale_oak_planks': '1.21.4',
  'minecraft:pale_oak_log': '1.21.4',
  'minecraft:pale_oak_leaves': '1.21.4',
  'minecraft:creaking_heart': '1.21.4',
  'minecraft:resin_block': '1.21.4',
  'minecraft:resin_bricks': '1.21.4',
};

// 查一个方块的加入版本。查不到返回 null —— 调用方必须显式处理，
// 不要在这里补默认值：补了就等于把「忘了登记」重新变成静默通道。
export function sinceOf(id) {
  return BLOCK_SINCE[id] ?? null;
}

// 把 "1.20.5" / "1.16.2" 这类版本串转成可比较的元组
// 段数不足时补 0："1.16" 要当成 [1,16,0]，否则与 "1.16.2" 比较时
// 缺的那一段是 undefined，`2 > undefined` 会得到 false，把本该保留的方块全滤掉
export function versionTuple(v) {
  const parts = String(v).split('.');
  return [0, 1, 2].map((i) => parseInt(parts[i], 10) || 0);
}

// 版本 a 是否 >= 版本 b
export function versionAtLeast(a, b) {
  const x = versionTuple(a);
  const y = versionTuple(b);
  for (let i = 0; i < 3; i++) {
    if (x[i] !== y[i]) return x[i] > y[i];
  }
  return true;
}
