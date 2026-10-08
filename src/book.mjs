// ybih 管理员设置书：文案与排版
// 排版模型：一页固定 BOOK_LINES 行，行数不足时用空行补齐，页脚永远落在最后一行
// 三个包共用同一份文案，只有文本组件的写法不同（JSON / SNBT）

export const BOOK_TITLE = '按钮游戏设置';
export const BOOK_AUTHOR = 'ybih';

// 一页显示多少行：书页文字区高 128 像素、行距 9 像素，128 / 9 = 14 行
export const BOOK_LINES = 14;

// 单行宽度上限（像素估算值）。书页文字区宽 114 像素，
// 这里留出余量：任何一行超过这个值就会折行，把页脚顶下去
export const BOOK_LINE_WIDTH = 100;

// 冷热提示的探测半径档位（格）。`distance=..N` 是选择器参数、只收字面量、代入不了记分板，
// 所以构建脚本按这份档位逐条生成扫描命令，书上那排半径选项也由它生成
export const HINT_RADII = [5, 10, 15, 20, 30, 50];

// 半径的默认档，必须出现在 HINT_RADII 里（构建时会校验）
export const HINT_RANGE_DEFAULT = 10;

const DIVIDER = '——————————';
const INDENT = '\u3000';

// 估算一行文字占多少像素：半角字符约 6 像素，全角字符 9 像素，空格 4 像素
export function textWidth(text) {
  let width = 0;
  for (const ch of String(text)) {
    const code = ch.codePointAt(0);
    if (ch === ' ') width += 4;
    else if (code < 0x2000) width += 6;
    else width += 9;
  }
  return width;
}

// 提示半径的选项：一档一行放两个，宽度刚好
const hintRadiusItems = HINT_RADII.map((r, i) => ({
  label: `${r} 格`,
  cmd: `function ybih:config/hint_r${r}`,
  tip: `探测半径：只看半径 ${r} 格内有没有别人的按钮`,
  sameRow: i % 2 === 0,
}));

// 设置项：label 是书上的文字，cmd 或 page 决定点击后做什么
export const BOOK_PAGES = [
  {
    title: '目录',
    compact: true,
    lines: [],
    items: [
      { prefix: '2页　', label: '开始/中止/重置', page: 2, tip: '开局操作：看设置、开始游戏、中止对局、重置数据' },
      { prefix: '3页　', label: '模式：经典/轮流', page: 3, tip: '经典＝每人各藏一个；轮流＝每轮只有一人藏' },
      { prefix: '4页　', label: '放错要不要确认', page: 4, tip: '放下按钮后要不要在聊天栏再点一次【确认】' },
      { prefix: '5页　', label: '集合点与边界', page: 5, tip: '集合点怎么设、活动边界开多大' },
      { prefix: '6页　', label: '开局准备倒计时', page: 6, tip: '点开始游戏后留多少秒做准备' },
      { prefix: '7页　', label: '一个人能藏多久', page: 7, tip: '藏匿时限，超时要扣分' },
      { prefix: '8页　', label: '搜寻阶段时长', page: 8, tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时' },
      { prefix: '9页　', label: '冷热提示', page: 9, tip: '多久提示一次、探测范围多大' },
      { prefix: '10页　', label: '轮末围观', page: 10, tip: '打完带大家看一圈，可以关掉' },
      { prefix: '11页　', label: '总轮数/周期', page: 11, tip: '一局打几轮；轮流模式下这里填周期数' },
      { prefix: '12页　', label: '规则与计分', page: 12, tip: '怎么算分、怎么排名' },
    ],
  },
  {
    title: '开局操作',
    note: '开局前先把集合点设好',
    lines: [],
    items: [
      { label: '查看当前设置', cmd: 'function ybih:config/notify', color: 'dark_purple', tip: '在聊天栏列出当前全部设置' },
      { label: '开始游戏', cmd: 'function ybih:start', color: 'dark_green', bold: true, tip: '集合点没设好会提示并拒绝开局' },
      { label: '中止当前对局', cmd: 'function ybih:stop', color: 'dark_red', bold: true, tip: '立刻结束本局，不结算、不播报排名' },
      { label: '重置全部数据', cmd: 'function ybih:reset', color: 'dark_red', bold: true, tip: '清空分数与按钮，保留设置和集合点' },
    ],
  },
  {
    title: '游戏模式',
    note: '对局进行中不能切换',
    lines: ['经典：每人各藏一个', '轮流：每轮只有一人藏'],
    items: [
      { label: '切到经典模式', cmd: 'function ybih:config/mode_1', color: 'dark_purple', tip: '每人各藏一个按钮，藏完一起找，按到别人的按钮得分' },
      { label: '切到轮流模式', cmd: 'function ybih:config/mode_2', color: 'dark_purple', tip: '每轮只有一人藏，其余人抢着按；按钮的分谁先按谁分高' },
    ],
  },
  {
    title: '放错确认',
    note: '放下后要不要再点一次',
    lines: ['开启：要再点一次确认', '关闭：放下就生效', '超时没确认要扣 1 分'],
    items: [
      { label: '开启确认', cmd: 'function ybih:config/confirm_on', color: 'dark_green', tip: '放下后在聊天栏点【确认】才生效，点【取消重放】可以收回重放' },
      { label: '关闭确认', cmd: 'function ybih:config/confirm_off', color: 'dark_red', tip: '放下立刻生效，不再弹确认；藏匿超时照样扣 1 分' },
    ],
  },
  {
    title: '点位与边界',
    note: '站到位置再点',
    lines: ['数字是半径，边长是两倍'],
    items: [
      { label: '集合点设在我脚下', cmd: 'function ybih:config/set_center_here', color: 'dark_purple', tip: '开局与搜寻阶段大家集合的位置；高空等待室建在它正上方' },
      { label: '边界开', cmd: 'function ybih:config/border_on', color: 'dark_green', tip: '开关只记设置，开局时才真正出现这圈边界', sameRow: true },
      { label: '边界关', cmd: 'function ybih:config/border_off', color: 'dark_red', tip: '立刻撤掉边界，恢复到没有边界的原版状态' },
      { label: '20', cmd: 'function ybih:config/border_r20', tip: '开局时按半径 20 生效（边界边长 40）', sameRow: true },
      { label: '30', cmd: 'function ybih:config/border_r30', tip: '开局时按半径 30 生效（边界边长 60）', sameRow: true },
      { label: '40', cmd: 'function ybih:config/border_r40', tip: '开局时按半径 40 生效（边界边长 80）' },
      { label: '50', cmd: 'function ybih:config/border_r50', tip: '开局时按半径 50 生效（边界边长 100）', sameRow: true },
      { label: '60', cmd: 'function ybih:config/border_r60', tip: '开局时按半径 60 生效（边界边长 120）', sameRow: true },
      { label: '70', cmd: 'function ybih:config/border_r70', tip: '开局时按半径 70 生效（边界边长 140）' },
      { label: '80', cmd: 'function ybih:config/border_r80', tip: '开局时按半径 80 生效（边界边长 160）', sameRow: true },
      { label: '90', cmd: 'function ybih:config/border_r90', tip: '开局时按半径 90 生效（边界边长 180）', sameRow: true },
      { label: '100', cmd: 'function ybih:config/border_r100', tip: '开局时按半径 100 生效（边界边长 200）' },
      { label: '跟随手动', cmd: 'function ybih:config/border_manual', tip: '开局不重设尺寸，沿用你自己敲的 /worldborder set；点它会顺带列出手动命令写法' },
    ],
  },
  {
    title: '准备阶段时长',
    note: '点开始游戏后的倒计时',
    lines: ['太短了人可能没到齐', '常用 10 秒'],
    items: [
      { label: '5 秒', cmd: 'function ybih:config/prep_5', tip: '准备阶段时长：点开始游戏到进入藏匿阶段', sameRow: true },
      { label: '10 秒', cmd: 'function ybih:config/prep_10', tip: '准备阶段时长：点开始游戏到进入藏匿阶段' },
      { label: '20 秒', cmd: 'function ybih:config/prep_20', tip: '准备阶段时长：点开始游戏到进入藏匿阶段', sameRow: true },
      { label: '30 秒', cmd: 'function ybih:config/prep_30', tip: '准备阶段时长：点开始游戏到进入藏匿阶段' },
    ],
  },
  {
    title: '一个人能藏多久',
    note: '藏匿时限',
    lines: ['超时没确认要扣 1 分', '地图大就选长一点'],
    items: [
      { label: '20 秒', cmd: 'function ybih:config/hide_20', tip: '从拿到按钮到确认藏好的时间上限', sameRow: true },
      { label: '30 秒', cmd: 'function ybih:config/hide_30', tip: '从拿到按钮到确认藏好的时间上限' },
      { label: '45 秒', cmd: 'function ybih:config/hide_45', tip: '从拿到按钮到确认藏好的时间上限', sameRow: true },
      { label: '60 秒', cmd: 'function ybih:config/hide_60', tip: '从拿到按钮到确认藏好的时间上限' },
      { label: '90 秒', cmd: 'function ybih:config/hide_90', tip: '从拿到按钮到确认藏好的时间上限', sameRow: true },
      { label: '120 秒', cmd: 'function ybih:config/hide_120', tip: '从拿到按钮到确认藏好的时间上限' },
    ],
  },
  {
    title: '搜寻阶段时长',
    note: '分拿完就不用等了',
    lines: ['分拿完就提前结束', '否则走满倒计时', '常用 300 - 600 秒'],
    items: [
      { label: '180 秒', cmd: 'function ybih:config/search_180', tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时', sameRow: true },
      { label: '300 秒', cmd: 'function ybih:config/search_300', tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时' },
      { label: '450 秒', cmd: 'function ybih:config/search_450', tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时', sameRow: true },
      { label: '600 秒', cmd: 'function ybih:config/search_600', tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时' },
      { label: '900 秒', cmd: 'function ybih:config/search_900', tip: '搜寻阶段时长上限：分被拿完就提前结束，否则走满倒计时' },
    ],
  },
  {
    title: '冷热提示',
    note: '只说有没有，不说在哪',
    lines: ['秒数是间隔，格数是半径'],
    items: [
      { label: '15 秒', cmd: 'function ybih:config/hint_15', tip: '每隔多久提示一次附近有没有别人的按钮', sameRow: true },
      { label: '30 秒', cmd: 'function ybih:config/hint_30', tip: '每隔多久提示一次附近有没有别人的按钮' },
      { label: '60 秒', cmd: 'function ybih:config/hint_60', tip: '每隔多久提示一次附近有没有别人的按钮', sameRow: true },
      { label: '120 秒', cmd: 'function ybih:config/hint_120', tip: '每隔多久提示一次附近有没有别人的按钮' },
      ...hintRadiusItems,
      { label: '关闭提示', cmd: 'function ybih:config/hint_off', color: 'dark_red', tip: '关掉冷热提示，完全靠自己找；半径设置会留着，下次开回来还是它' },
    ],
  },
  {
    title: '轮末围观',
    note: '打完之后带大家看一圈',
    lines: ['每个藏过的都会展示', '分拿完的会临时摆回去'],
    items: [
      { label: '围观开', cmd: 'function ybih:config/showcase_on', color: 'dark_green', tip: '轮末把本局每一个藏过的按钮依次展示一遍；分被拿完的方块收走了，会按记录临时摆回原位给人看一眼', sameRow: true },
      { label: '围观关', cmd: 'function ybih:config/showcase_off', color: 'dark_red', tip: '轮末直接结算，不做传送展示' },
    ],
  },
  {
    title: '总轮数 / 周期',
    note: '分数跨轮累计',
    lines: ['经典：全员各藏一次', '轮流：这里填周期数', '一局 = 周期 × 人数'],
    items: [
      { label: '1 轮', cmd: 'function ybih:config/rounds_1', tip: '一局打几轮；轮流模式下这里填周期数，总轮数 = 周期数 × 人数', sameRow: true },
      { label: '2 轮', cmd: 'function ybih:config/rounds_2', tip: '一局打几轮；轮流模式下这里填周期数，总轮数 = 周期数 × 人数' },
      { label: '3 轮', cmd: 'function ybih:config/rounds_3', tip: '一局打几轮；轮流模式下这里填周期数，总轮数 = 周期数 × 人数', sameRow: true },
      { label: '5 轮', cmd: 'function ybih:config/rounds_5', tip: '一局打几轮；轮流模式下这里填周期数，总轮数 = 周期数 × 人数' },
      { label: '8 轮', cmd: 'function ybih:config/rounds_8', tip: '一局打几轮；轮流模式下这里填周期数，总轮数 = 周期数 × 人数' },
    ],
  },
  {
    title: '规则与计分',
    lines: [
      '每个按钮都带着分',
      '　初始 = 参与人数 − 1',
      '每人每个按钮只算一次',
      '　按到就从它取走一份',
      '　取完一份它就少一分',
      '谁先按谁分高',
      '分被拿光的按钮会消失',
      '分拿完就提前收官',
      '同分再比发现次数与先后',
    ],
    items: [],
  },
];

// 把一页排成若干行；每行是若干个片段，空数组表示一个空行
//
// 配色约定 —— 书页是浅米黄底，十六色里只有深色系读得清，亮色一律发虚，所以只用这五个：
//   dark_red    页标题（朱批感，纸面上最跳）与关闭、危险操作
//   black       正文与普通设置项，写成墨色最像书
//   dark_green  开启 / 启动
//   dark_purple 查看、切换、定位这类动作，以及页脚的目录链接
//   dark_gray   副标题、分隔线、说明、页脚这些辅助信息
//
// 样式约定：可点项一律加下划线 —— 书页上没有按钮外观，下划线是「这一行能点」最直接的信号；
// 加粗则留给开局、中止、重置三个关键动作，由条目自己声明 bold。
export function pageContentRows(page) {
  const rows = [];
  rows.push([{ text: `【${page.title}】`, color: 'dark_red' }]);
  if (page.note) rows.push([{ text: page.note, color: 'dark_gray', italic: true }]);
  if (!page.compact) {
    rows.push([{ text: DIVIDER, color: 'dark_gray' }]);
    rows.push([]);
  }

  const desc = page.lines ?? [];
  for (const text of desc) rows.push([{ text, color: 'dark_gray' }]);
  if (desc.length > 0 && page.items.length > 0) rows.push([]);

  let row = [];
  for (const item of page.items) {
    if (item.prefix) row.push({ text: item.prefix, color: 'dark_gray' });
    row.push({
      text: item.prefix ? item.label : `· ${item.label}`,
      color: item.color ?? 'black',
      bold: item.bold,
      underlined: true,
      cmd: item.cmd,
      page: item.page,
      tip: item.tip,
    });
    if (item.sameRow) row.push({ text: INDENT, color: 'dark_gray' });
    else {
      rows.push(row);
      row = [];
    }
  }
  if (row.length > 0) rows.push(row);
  return rows;
}

// 整页行数：内容 + 补足的空行 + 空行 + 页脚，页脚固定在第 BOOK_LINES 行
// 内容已经超出页面时不再补行（页脚会被顶下去，构建校验会直接报错）
export function pageLines(page, index, total) {
  const out = pageContentRows(page);
  const limit = BOOK_LINES - 2;
  if (out.length > limit) return out;
  while (out.length < limit) out.push([]);
  out.push([]);
  out.push(footerRow(index, total));
  return out;
}

function footerRow(index, total) {
  if (index === 0) return [{ text: '点一行跳到那一页', color: 'dark_gray', italic: true }];
  return [
    { text: `第 ${index + 1} / ${total} 页　`, color: 'dark_gray', italic: true },
    { text: '目录', color: 'dark_purple', underlined: true, page: 1, tip: '回到目录页' },
  ];
}

// JSON 文本组件（包 1、包 2）
// 书页是「装着 JSON 的字符串」，换行要经过两层：先给 JSON 写一个 \n 转义（文件里是 \\n），
// Brigadier 解掉一层、JSON 再解一层，最后才是真正的换行
function pageToJson(rows) {
  const parts = [];
  rows.forEach((row) => {
    if (row.length === 0) {
      parts.push({ text: '\\n' });
      return;
    }
    row.forEach((part, i) => {
      const o = { text: i === row.length - 1 ? `${part.text}\\n` : part.text };
      if (part.color) o.color = part.color;
      if (part.bold) o.bold = true;
      if (part.italic) o.italic = true;
      if (part.underlined) o.underlined = true;
      if (part.cmd) o.clickEvent = { action: 'run_command', value: `/${part.cmd}` };
      if (part.page) o.clickEvent = { action: 'change_page', value: String(part.page) };
      if (part.tip) o.hoverEvent = { action: 'show_text', contents: part.tip };
      parts.push(o);
    });
  });
  return JSON.stringify(parts);
}

// SNBT 字符串：反斜杠要转义，换行写成 \n 转义（1.21.5 的 SNBT 认这个转义）
function snbtQuote(value) {
  const s = String(value)
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\n/g, '\\n');
  return `'${s}'`;
}

// SNBT 内联组件（包 3）：书页本身就是文本组件，跳页页号是整数，
// 悬停文字用 hover_event 的 value 字段
function pageToSnbt(rows) {
  const parts = [];
  rows.forEach((row) => {
    if (row.length === 0) {
      parts.push(`{text:${snbtQuote('\n')}}`);
      return;
    }
    row.forEach((part, i) => {
      const text = i === row.length - 1 ? `${part.text}\n` : part.text;
      let s = `{text:${snbtQuote(text)}`;
      if (part.color) s += `,color:${snbtQuote(part.color)}`;
      if (part.bold) s += ',bold:true';
      if (part.italic) s += ',italic:true';
      if (part.underlined) s += ',underlined:true';
      if (part.cmd) s += `,click_event:{action:${snbtQuote('run_command')},command:${snbtQuote('/' + part.cmd)}}`;
      if (part.page) s += `,click_event:{action:${snbtQuote('change_page')},page:${part.page}}`;
      if (part.tip) s += `,hover_event:{action:${snbtQuote('show_text')},value:${snbtQuote(part.tip)}}`;
      parts.push(s + '}');
    });
  });
  return '[' + parts.join(',') + ']';
}

// 生成 give 一本书的命令
// 包 1、包 2：书页是「装着 JSON 的字符串」，所以整页要用单引号包起来
// 包 3（1.21.5 起）：书页本身就是文本组件，直接用组件列表，不再套字符串
function bookCommandFrom(pack, title, author, pages) {
  const titleField = `"${title}"`;
  const total = pages.length;
  const rows = pages.map((page, index) => pageLines(page, index, total));
  if (pack.bookStyle === 'component-snbt') {
    const pageList = rows.map((r) => pageToSnbt(r)).join(',');
    return `give @s minecraft:written_book[minecraft:written_book_content={pages:[${pageList}],title:${titleField},author:"${author}"}]`;
  }
  const pageList = rows.map((r) => `'${pageToJson(r)}'`).join(',');
  if (pack.bookStyle === 'legacy') {
    return `give @s minecraft:written_book{pages:[${pageList}],title:${titleField},author:"${author}"}`;
  }
  return `give @s minecraft:written_book[minecraft:written_book_content={pages:[${pageList}],title:${titleField},author:"${author}"}]`;
}

export function bookCommand(pack) {
  return bookCommandFrom(pack, BOOK_TITLE, BOOK_AUTHOR, BOOK_PAGES);
}

// ── 等待室九宫格棋的说明书 ────────────────────────────────────────
//
// 和设置书同一套排版，但按下去提交的是 trigger 值而不是 /function：
// 书页的 run_command 以玩家本人身份执行，而参赛者没有 OP，写 /function 会被服务端拒绝。
// /trigger 是人人都能用的通道，等待室里的点击入口一律走它 —— 棋盘上的空格子也一样。
//
// **书里放不下玩家名**：书页内容在构建期就写死了，原版没办法在运行时把玩家名插进来。
// 所以「挑对手」只能在聊天栏点（那里能用 {"selector"} 取到真名），
// 书里放的是玩法说明与【刷新名单】。
export const TTT_BOOK_TITLE = '九宫格棋';
export const TTT_BOOK_AUTHOR = 'ybih';

export const TTT_BOOK_PAGES = [
  {
    title: '九宫格棋',
    note: '等待室里的两人对局',
    lines: ['看完这一页就翻开书', '先点【刷新名单】', '名单贴在聊天栏里', '点谁后面的【邀请】'],
    items: [
      {
        label: '刷新名单',
        cmd: 'trigger ybih.trigger set 11',
        color: 'gold',
        tip: '重贴聊天栏名单，顺便把状态找回来；有人进出就按一下',
      },
      {
        label: '离座',
        cmd: 'trigger ybih.trigger set 12',
        color: 'dark_red',
        tip: '退出当前这一局，让对手回到空闲',
      },
      {
        label: '看我的棋盘',
        cmd: 'trigger ybih.trigger set 13',
        color: 'dark_purple',
        tip: '把你这张棋盘重新贴一遍到聊天栏',
      },
    ],
  },
  {
    title: '怎么下',
    note: '棋盘在聊天栏里',
    lines: [
      '名单里点【邀请】挑人',
      '他点【同意】就开局',
      '邀请的人执 ✕ 先走',
      '再开一局就换先手',
      '空位是带数字的灰格子',
      '点那个数字就落子',
      '落过的格子点不动',
      '连成三子当场通报',
    ],
    items: [],
  },
];

export function tttBookCommand(pack) {
  return bookCommandFrom(pack, TTT_BOOK_TITLE, TTT_BOOK_AUTHOR, TTT_BOOK_PAGES);
}
