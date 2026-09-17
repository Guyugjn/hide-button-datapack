// 方块 ID 的加入版本表：构建时据此过滤 placeable_surfaces，并为校验提供依据。
// 只登记「跨版本会踩坑」的方块，未登记的按 1.16 起就有处理。
//
// 数据来源：
//   1.16.5 客户端 jar 的 assets/minecraft/blockstates/ 全量清单（764 项，作为 1.16 基准）
//   1.17 / 1.19 / 1.20 的官方更新日志与 wiki 版本页
//
// 版本号写成数字，比较时按 (主, 次) 处理：1.16 < 1.16.2 < 1.17 < 1.20 < 1.20.5 < 1.21

export const BLOCK_SINCE = {
  // 1.17 洞穴与山崖
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

  // 1.19 荒野更新
  'minecraft:mangrove_planks': '1.19',
  'minecraft:mangrove_log': '1.19',
  'minecraft:mangrove_leaves': '1.19',
  'minecraft:mud': '1.19',
  'minecraft:mud_bricks': '1.19',
  'minecraft:muddy_mangrove_roots': '1.19',
  'minecraft:packed_mud': '1.19',
  'minecraft:sculk': '1.19',

  // 1.20 轨迹与故事
  'minecraft:bamboo_planks': '1.20',
  'minecraft:bamboo_mosaic': '1.20',
  'minecraft:cherry_planks': '1.20',
  'minecraft:cherry_log': '1.20',
  'minecraft:cherry_leaves': '1.20',
  'minecraft:stripped_cherry_log': '1.20',
  'minecraft:chiseled_bookshelf': '1.20',

  // 1.20.5 / 1.21
  'minecraft:pale_oak_planks': '1.21.4',
  'minecraft:pale_oak_log': '1.21.4',
  'minecraft:pale_oak_leaves': '1.21.4',
  'minecraft:creaking_heart': '1.21.4',
  'minecraft:resin_block': '1.21.4',
  'minecraft:resin_bricks': '1.21.4',

  // 1.21
  'minecraft:tuff_bricks': '1.21',
  'minecraft:chiseled_tuff': '1.21',
  'minecraft:polished_tuff': '1.21',
  'minecraft:copper_bulb': '1.21',
  'minecraft:copper_grate': '1.21',
  'minecraft:chiseled_copper': '1.21',
  'minecraft:crafting_table': '1.16',
};

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
