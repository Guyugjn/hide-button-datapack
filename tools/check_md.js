const fs = require('fs');
const file = process.argv[2] || 'README.md';
const raw = fs.readFileSync(file, 'utf8');
const lines = raw.split('\n');
let issues = 0;

const bt = String.fromCharCode(96); // 反引号

// 连续空行
for (let i = 1; i < lines.length; i++) {
  if (lines[i] === '' && lines[i - 1] === '') {
    console.log('连续空行 @' + (i + 1));
    issues++;
  }
}

// 行内元素只检查围栏外的正文行。
// 加粗按「段落」配对，不按整篇配对，也不按单行配对：
//   · 按整篇配对（旧行为）会把两处互不相干的孤立 ** 凑成偶数，错误越多越容易漏，
//     而且报错只有「整篇总数是奇数」，说不出在哪一行；
//   · 按单行配对会把跨软换行的合法强调判成错误 —— CommonMark 允许强调跨软换行，
//     手写文档在换行处把 **…** 断开是正常写法，实测仓库里就有 5 对；
//   · 段落（连续非空行）正好是 CommonMark 里强调能跨越的最大范围：可以跨软换行，
//     但不能跨空行。所以按段内配对既抓得住真错误，又不会误报跨行写法。
// 残留弱点（已知、可接受）：判定用的是段内 `**` 总数的奇偶，所以一段里若有**偶数个**
// 未闭合标记（例如两个），它们会互相抵消、整段看起来「成对」。注意一个合法加粗贡献 2 个
// 标记，不会抵消掉 1 个未闭合标记（2 + 1 = 3，仍是奇数，照样报出）—— 抵消只发生在
// 未闭合标记自身成偶数个的时候。要彻底堵死得做真正的行内强调解析（还要处理 * / _ / 转义 /
// 行内代码 / 链接），对一个文档格式检查器来说不值得。判定范围已从旧版的「整篇任意两行」
// 收窄到「同一段内」，两个错误落在不同段落时各报各的，比原来可靠得多，故到此为止。
let inFence = false;
let prevHeading = 0;
let para = []; // 当前段落里 [行号, 该行 ** 个数]

// 行内代码（`…`）与围栏代码块一样屏蔽强调：`` `** 这是正文 **` `` 里的星号不该参与配对。
// 成对的同长度反引号之间的内容整段替换成空格；反引号不成对的行原样返回
// （那种行本身就由下面的反引号检查报出，这里不去猜它的边界）
function stripInlineCode(line) {
  return line.replace(/(`+)[\s\S]*?\1/g, ' ');
}

function flushPara() {
  if (!para.length) return;
  const total = para.reduce((a, p) => a + p[1], 0);
  if (total % 2 !== 0) {
    const odd = para.filter((p) => p[1] % 2 !== 0).map((p) => p[0]);
    const from = para[0][0];
    const to = para[para.length - 1][0];
    const where = from === to ? '第 ' + from + ' 行' : '第 ' + from + '–' + to + ' 行这一段';
    console.log(
      '加粗标记不成对：' + where + '的 ** 总数为奇数（' + total + '），' +
        '该范围内含奇数个 ** 的行：' + (odd.length ? odd.join('、') : '（跨行混排）'),
    );
    issues++;
  }
  para = [];
}

lines.forEach((l, i) => {
  const fence = l.trimStart().startsWith(bt + bt + bt);
  if (fence) {
    flushPara(); // 围栏两侧是不同段落，不能跨围栏配对
    inFence = !inFence;
    return;
  }
  if (inFence) return;

  // 空行断开段落；代码块里的星号是正文，压根不参与配对（上面已 return）
  if (l.trim() === '') {
    flushPara();
  } else {
    para.push([i + 1, (stripInlineCode(l).match(/\*\*/g) || []).length]);
  }

  if (/^-\s*$/.test(l)) {
    console.log('空列表项 @' + (i + 1));
    issues++;
  }

  const nbt = l.split(bt).length - 1;
  if (nbt % 2 !== 0) {
    console.log('反引号不成对 @' + (i + 1) + ': ' + l.slice(0, 70));
    issues++;
  }

  const m = l.match(/^(#{1,6})\s/);
  if (m) {
    const lvl = m[1].length;
    if (prevHeading && lvl > prevHeading + 1) {
      console.log('标题跳级 @' + (i + 1) + ': ' + l.slice(0, 60));
      issues++;
    }
    prevHeading = lvl;
  }
});

flushPara();

if (inFence) {
  console.log('代码围栏未闭合');
  issues++;
}

console.log(issues ? '\n共 ' + issues + ' 处问题' : '格式检查通过');
// 报出问题就要有非零退出码，否则接进 CI 或 && 串联会永远通过，检查形同装饰
if (issues > 0) process.exitCode = 1;
