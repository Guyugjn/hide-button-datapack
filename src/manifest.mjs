// ybih 数据包构建配置：定义 3 个分版本包的差异
// 运行 node tools/build.mjs 生成 dist/ 下的产物

import { HINT_RADII } from './book.mjs';

// 按钮材质清单（按 Minecraft 版本加入顺序）
const BASE_MATERIALS = [
  'oak',
  'spruce',
  'birch',
  'jungle',
  'acacia',
  'dark_oak',
  'crimson',
  'warped',
  'stone',
  'polished_blackstone',
];
const V119_MATERIALS = ['mangrove'];
const V120_MATERIALS = ['bamboo', 'cherry'];
const V1214_MATERIALS = ['pale_oak'];

// 文本组件写法
export const TEXT_JSON = {
  TXT_S: '{"text":"',
  TXT_M: '","color":"',
  TXT_E: '"}',
  SEL_S: '{"selector":"',
  SEL_E: '"}',
  SCORE_TIMER: '{"score":{"name":"#timer","objective":"ybih.config"}}',
  SCORE_HIDE: '{"score":{"name":"#hide_timer","objective":"ybih.config"}}',
  SCORE_HIDETIME: '{"score":{"name":"#hide_time","objective":"ybih.config"}}',
  SCORE_ROUND: '{"score":{"name":"#round","objective":"ybih.config"}}',
  SCORE_ROUNDS: '{"score":{"name":"#rounds","objective":"ybih.config"}}',
  SCORE_PREP: '{"score":{"name":"#prep_time","objective":"ybih.config"}}',
  SCORE_SEARCH: '{"score":{"name":"#search_time","objective":"ybih.config"}}',
  SCORE_HINT: '{"score":{"name":"#hint_period","objective":"ybih.config"}}',
  SCORE_HINTRANGE: '{"score":{"name":"#hint_range","objective":"ybih.config"}}',
  SCORE_SELF: '{"score":{"name":"@s","objective":"ybih.score"}}',
  SCORE_BUTTONS: '{"score":{"name":"#button_count","objective":"ybih.config"}}',
  SCORE_GAINED: '{"score":{"name":"#gained","objective":"ybih.config"}}',
  SCORE_RANK: '{"score":{"name":"#ranked","objective":"ybih.config"}}',
  SCORE_FOUNDSEQ: '{"score":{"name":"#found_seq","objective":"ybih.config"}}',
  SCORE_SEEKERS: '{"score":{"name":"#seekers_left","objective":"ybih.config"}}',
  SCORE_ROUNDSTOTAL: '{"score":{"name":"#rounds_total","objective":"ybih.config"}}',
  SCORE_CYCLE: '{"score":{"name":"#cycle","objective":"ybih.config"}}',
  SCORE_CD_MIN: '{"score":{"name":"#cd_min","objective":"ybih.config"}}',
  SCORE_CD_S10: '{"score":{"name":"#cd_s10","objective":"ybih.config"}}',
  SCORE_CD_S1: '{"score":{"name":"#cd_s1","objective":"ybih.config"}}',
  SCORE_BORDER_R: '{"score":{"name":"#border_r","objective":"ybih.config"}}',
  SCORE_BW: '{"score":{"name":"#bw_now","objective":"ybih.config"}}',
  SCORE_SHOWIDX: '{"score":{"name":"#show_idx","objective":"ybih.config"}}',
  SCORE_SHOWTOTAL: '{"score":{"name":"#show_total","objective":"ybih.config"}}',
  SCORE_SHOWSEC: '{"score":{"name":"#show_sec","objective":"ybih.config"}}',
  SCORE_FINDS: '{"score":{"name":"@s","objective":"ybih.finds"}}',
  BTN_CONFIRM:
    '{"text":"【确认】","color":"green","clickEvent":{"action":"run_command","value":"/trigger ybih.trigger set 1"}}',
  BTN_REDO:
    '{"text":"【取消重放】","color":"red","clickEvent":{"action":"run_command","value":"/trigger ybih.trigger set 2"}}',
};

export const TEXT_SNBT = {
  TXT_S: "{text:'",
  TXT_M: "',color:'",
  TXT_E: "'}",
  SEL_S: "{selector:'",
  SEL_E: "'}",
  SCORE_TIMER: "{score:{name:'#timer',objective:'ybih.config'}}",
  SCORE_HIDE: "{score:{name:'#hide_timer',objective:'ybih.config'}}",
  SCORE_HIDETIME: "{score:{name:'#hide_time',objective:'ybih.config'}}",
  SCORE_ROUND: "{score:{name:'#round',objective:'ybih.config'}}",
  SCORE_ROUNDS: "{score:{name:'#rounds',objective:'ybih.config'}}",
  SCORE_PREP: "{score:{name:'#prep_time',objective:'ybih.config'}}",
  SCORE_SEARCH: "{score:{name:'#search_time',objective:'ybih.config'}}",
  SCORE_HINT: "{score:{name:'#hint_period',objective:'ybih.config'}}",
  SCORE_HINTRANGE: "{score:{name:'#hint_range',objective:'ybih.config'}}",
  SCORE_SELF: "{score:{name:'@s',objective:'ybih.score'}}",
  SCORE_BUTTONS: "{score:{name:'#button_count',objective:'ybih.config'}}",
  SCORE_GAINED: "{score:{name:'#gained',objective:'ybih.config'}}",
  SCORE_RANK: "{score:{name:'#ranked',objective:'ybih.config'}}",
  SCORE_FOUNDSEQ: "{score:{name:'#found_seq',objective:'ybih.config'}}",
  SCORE_SEEKERS: "{score:{name:'#seekers_left',objective:'ybih.config'}}",
  SCORE_ROUNDSTOTAL: "{score:{name:'#rounds_total',objective:'ybih.config'}}",
  SCORE_CYCLE: "{score:{name:'#cycle',objective:'ybih.config'}}",
  SCORE_CD_MIN: "{score:{name:'#cd_min',objective:'ybih.config'}}",
  SCORE_CD_S10: "{score:{name:'#cd_s10',objective:'ybih.config'}}",
  SCORE_CD_S1: "{score:{name:'#cd_s1',objective:'ybih.config'}}",
  SCORE_BORDER_R: "{score:{name:'#border_r',objective:'ybih.config'}}",
  SCORE_BW: "{score:{name:'#bw_now',objective:'ybih.config'}}",
  SCORE_SHOWIDX: "{score:{name:'#show_idx',objective:'ybih.config'}}",
  SCORE_SHOWTOTAL: "{score:{name:'#show_total',objective:'ybih.config'}}",
  SCORE_SHOWSEC: "{score:{name:'#show_sec',objective:'ybih.config'}}",
  SCORE_FINDS: "{score:{name:'@s',objective:'ybih.finds'}}",
  BTN_CONFIRM:
    "{text:'【确认】',color:'green',click_event:{action:'run_command',command:'/trigger ybih.trigger set 1'}}",
  BTN_REDO:
    "{text:'【取消重放】',color:'red',click_event:{action:'run_command',command:'/trigger ybih.trigger set 2'}}",
};

// 物品语法：legacy=NBT，componentA=1.20.5 组件谓词数组，componentB=1.21.5 组件谓词单元素
function giveLegacy(material) {
  return `minecraft:${material}_button{CanPlaceOn:["#ybih:placeable_surfaces"],HideFlags:16}`;
}
// 1.20.5–1.21.4：组件值收谓词数组。
// 这段区间隐藏提示行用 hide_additional_tooltip 而非 HideFlags（后者在 1.20.5 被拆成组件）。
// tooltip_display 要到 1.21.5 才加入，本包用不了
function giveComponentA(material) {
  return `minecraft:${material}_button[minecraft:can_place_on={predicates:[{blocks:"#ybih:placeable_surfaces"}]},minecraft:hide_additional_tooltip={}]`;
}
// 1.21.5 起 predicates 层被去掉，组件值直接收方块谓词本身。
// 写成一层的 map，不写成列表：列表形式实测报 `Not a map`
// 客户端会把 can_place_on 里的标签展开成全部方块名，提示框会挡住物品名。
// 1.21.5 起用 tooltip_display 隐藏该组件（hide_additional_tooltip 已被移除）
function giveComponentB(material) {
  return `minecraft:${material}_button[minecraft:can_place_on={blocks:"#ybih:placeable_surfaces"},minecraft:tooltip_display={hidden_components:["minecraft:can_place_on"]}]`;
}

// 按钮的 12 种朝向状态：注册时记下，破坏后按原状态还原，避免恢复出来的按钮悬空点不到
export const BUTTON_FACINGS = [
  { tag: 'ybih_f_floor_n', state: 'face=floor,facing=north' },
  { tag: 'ybih_f_floor_s', state: 'face=floor,facing=south' },
  { tag: 'ybih_f_floor_e', state: 'face=floor,facing=east' },
  { tag: 'ybih_f_floor_w', state: 'face=floor,facing=west' },
  { tag: 'ybih_f_ceil_n', state: 'face=ceiling,facing=north' },
  { tag: 'ybih_f_ceil_s', state: 'face=ceiling,facing=south' },
  { tag: 'ybih_f_ceil_e', state: 'face=ceiling,facing=east' },
  { tag: 'ybih_f_ceil_w', state: 'face=ceiling,facing=west' },
  { tag: 'ybih_f_wall_n', state: 'face=wall,facing=north' },
  { tag: 'ybih_f_wall_s', state: 'face=wall,facing=south' },
  { tag: 'ybih_f_wall_e', state: 'face=wall,facing=east' },
  { tag: 'ybih_f_wall_w', state: 'face=wall,facing=west' },
];

// ── 管理员设置书 ────────────────────────────────────────────────

// 每一个可选数值都生成一个函数：改值之后统一调用反馈函数，保证有点击音效和聊天栏回执
export const SETTING_FUNCS = [
  { name: 'prep_5', score: '#prep_time', value: 5 },
  { name: 'prep_10', score: '#prep_time', value: 10 },
  { name: 'prep_20', score: '#prep_time', value: 20 },
  { name: 'prep_30', score: '#prep_time', value: 30 },
  { name: 'hide_20', score: '#hide_time', value: 20 },
  { name: 'hide_30', score: '#hide_time', value: 30 },
  { name: 'hide_45', score: '#hide_time', value: 45 },
  { name: 'hide_60', score: '#hide_time', value: 60 },
  { name: 'hide_90', score: '#hide_time', value: 90 },
  { name: 'hide_120', score: '#hide_time', value: 120 },
  { name: 'search_180', score: '#search_time', value: 180 },
  { name: 'search_300', score: '#search_time', value: 300 },
  { name: 'search_450', score: '#search_time', value: 450 },
  { name: 'search_600', score: '#search_time', value: 600 },
  { name: 'search_900', score: '#search_time', value: 900 },
  { name: 'hint_15', score: '#hint_period', value: 15 },
  { name: 'hint_30', score: '#hint_period', value: 30 },
  { name: 'hint_60', score: '#hint_period', value: 60 },
  { name: 'hint_120', score: '#hint_period', value: 120 },
  { name: 'hint_off', score: '#hint_period', value: 99999 },
  // 提示半径：distance=..N 只收字面量、代入不了记分板，档位表在 book.mjs 的 HINT_RADII
  ...HINT_RADII.map((r) => ({ name: `hint_r${r}`, score: '#hint_range', value: r })),
  { name: 'rounds_1', score: '#rounds', value: 1 },
  { name: 'rounds_2', score: '#rounds', value: 2 },
  { name: 'rounds_3', score: '#rounds', value: 3 },
  { name: 'rounds_5', score: '#rounds', value: 5 },
  { name: 'rounds_8', score: '#rounds', value: 8 },
  // 边界半径：只在开局时落到世界上，所以这些设置项不带 after；value 0 表示跟随手动设的尺寸
  // value 同时是 worldborder set 的换算依据（边长 = 半径 × 2），加到档位表要同步 border_apply
  { name: 'border_r20', score: '#border_r', value: 20 },
  { name: 'border_r30', score: '#border_r', value: 30 },
  { name: 'border_r40', score: '#border_r', value: 40 },
  { name: 'border_r50', score: '#border_r', value: 50 },
  { name: 'border_r60', score: '#border_r', value: 60 },
  { name: 'border_r70', score: '#border_r', value: 70 },
  { name: 'border_r80', score: '#border_r', value: 80 },
  { name: 'border_r90', score: '#border_r', value: 90 },
  { name: 'border_r100', score: '#border_r', value: 100 },
  // 选「跟随手动」时顺带把手动命令的写法贴出来，等于把帮助入口并进了这一项
  { name: 'border_manual', score: '#border_r', value: 0, after: 'function ybih:config/border_help' },
];

// 书的排版与文案都在 src/book.mjs，这里只做转出
export {
  BOOK_TITLE,
  BOOK_AUTHOR,
  BOOK_PAGES,
  BOOK_LINES,
  BOOK_LINE_WIDTH,
  HINT_RADII,
  HINT_RANGE_DEFAULT,
  bookCommand,
  pageContentRows,
  pageLines,
  textWidth,
} from './book.mjs';

export const PACKS = [
  {
    id: 'ybih-1.16.2-1.20.4',
    label: '1.16.2 – 1.20.4',
    versions: '1.16.2、1.16.3、1.16.4、1.16.5、1.17、1.18、1.19、1.20.1、1.20.2、1.20.3、1.20.4',
    // 该包覆盖区间的下限。方块白名单按它过滤，只保留这个版本已存在的方块。
    // 起点取 1.16.2：1.16 / 1.16.1 的格式号是 5，且不认标签里的 required 对象写法，
    // 要覆盖它们得再拆一版标签，收益不抵复杂度
    minVersion: '1.16.2',
    mcmeta: {
      pack_format: 6,
      supported_formats: { min_inclusive: 6, max_inclusive: 26 },
    },
    // 按下判定的进度触发器：any_block_use 是 1.20.5 才加的，本包区间只能用 item_used_on_block
    tokens: { ...TEXT_JSON, USE_TRIGGER: 'item_used_on_block' },
    materials: [...BASE_MATERIALS],
    give: giveLegacy,
    bookStyle: 'legacy',
    // 1.16–1.20.4 一律读复数目录；单数那份是冗余备份，留着无害
    pluralFunctions: true,
    singularFunctions: true,
    // 标签与进度目录在 1.21 才改名，本包区间内都是复数
    pluralTags: true,
    singularTags: false,
    pluralAdv: true,
    singularAdv: false,
    // 高空等待室的基准高度。1.16–1.17 的建筑上限只到 255，所以这包不能超过它
    waitRoomY: 245,
  },
  {
    id: 'ybih-1.20.5-1.21.4',
    label: '1.20.5 – 1.21.4',
    versions: '1.20.5、1.20.6、1.21、1.21.1、1.21.2、1.21.3、1.21.4',
    minVersion: '1.20.5',
    mcmeta: {
      pack_format: 41,
      supported_formats: { min_inclusive: 41, max_inclusive: 61 },
    },
    // 1.20.5 起 item_used_on_block 不再对空手交互触发，改用覆盖所有方块交互的 any_block_use
    tokens: { ...TEXT_JSON, USE_TRIGGER: 'any_block_use' },
    materials: [...BASE_MATERIALS, ...V119_MATERIALS, ...V120_MATERIALS],
    give: giveComponentA,
    bookStyle: 'component-json',
    // 本包跨 1.21 的目录改名：1.20.5–1.20.6 读复数，1.21–1.21.4 读单数，两份都要放
    pluralFunctions: true,
    singularFunctions: true,
    // 标签与进度目录同样是 1.21 改名，单数与复数都要放
    pluralTags: true,
    singularTags: true,
    pluralAdv: true,
    singularAdv: true,
    // 1.18 起可放置范围是 -64~319、自然地形最高到 256，抬到它上面才躲得开山体
    waitRoomY: 300,
  },
  {
    id: 'ybih-1.21.5-26.2',
    label: '1.21.5 – 26.2',
    versions: '1.21.5 至 1.21.11、26.1、26.2',
    minVersion: '1.21.5',
    mcmeta: {
      pack_format: 71,
      supported_formats: { min_inclusive: 71, max_inclusive: 107 },
      min_format: [71, 0],
      max_format: [107, 1],
    },
    tokens: { ...TEXT_SNBT, USE_TRIGGER: 'any_block_use' },
    materials: [...BASE_MATERIALS, ...V119_MATERIALS, ...V120_MATERIALS, ...V1214_MATERIALS],
    give: giveComponentB,
    bookStyle: 'component-snbt',
    pluralFunctions: false,
    singularFunctions: true,
    pluralTags: false,
    singularTags: true,
    pluralAdv: false,
    singularAdv: true,
    waitRoomY: 300,
  },
];

export const MATERIAL_TO_BLOCK = (material) => `minecraft:${material}_button`;
export const MATERIAL_TO_TAG = (material) => `ybih_btn_${material}_button`;
