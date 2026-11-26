/* Nucleo offline compartilhado pelos widgets de validacao e metricas.
   Gera dados sinteticos deterministicos, calcula curvas ROC e PR e desenha SVG. */
(function(global){
  'use strict';

  /* Gerador pseudoaleatorio deterministico (Mulberry32) */
  function makeRng(seed){
    let a = seed >>> 0;
    return function(){
      a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  /* Normal padrao por Box-Muller */
  function makeNormal(rng){
    return function(){
      let u = 0;
      while(u === 0) u = rng();
      return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * rng());
    };
  }

  /* Funcao de distribuicao normal padrao (aproximacao de Abramowitz e Stegun 7.1.26) */
  function phi(x){
    const z = Math.abs(x) / Math.SQRT2;
    const t = 1 / (1 + 0.3275911 * z);
    const erf = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-z * z);
    return x >= 0 ? 0.5 * (1 + erf) : 0.5 * (1 - erf);
  }

  /* Escores binormais: negativos ~ N(0,1), positivos ~ N(d,1) */
  function binormal(n, prevalence, d, seed){
    const rng = makeRng(seed);
    const rnorm = makeNormal(rng);
    const nPos = Math.max(1, Math.round(n * prevalence));
    const out = [];
    for(let i = 0; i < n; i++){
      const y = i < nPos ? 1 : 0;
      out.push({ y: y, s: rnorm() + (y === 1 ? d : 0) });
    }
    return out;
  }

  /* Curva ROC empirica, AUC trapezoidal (equivale a Mann-Whitney com empates) */
  function rocCurve(data){
    const sorted = data.slice().sort(function(a, b){ return b.s - a.s; });
    let P = 0, N = 0;
    for(const r of sorted){ if(r.y === 1) P++; else N++; }
    const pts = [{ fpr: 0, tpr: 0, thr: Infinity }];
    let tp = 0, fp = 0, auc = 0, prevF = 0, prevT = 0;
    for(let i = 0; i < sorted.length; i++){
      if(sorted[i].y === 1) tp++; else fp++;
      if(i === sorted.length - 1 || sorted[i + 1].s !== sorted[i].s){
        const f = fp / N, t = tp / P;
        auc += (f - prevF) * (t + prevT) / 2;
        pts.push({ fpr: f, tpr: t, thr: sorted[i].s });
        prevF = f; prevT = t;
      }
    }
    return { points: pts, auc: auc, P: P, N: N };
  }

  /* Curva precisao-revocacao e precisao media (AP) em degraus */
  function prCurve(data){
    const sorted = data.slice().sort(function(a, b){ return b.s - a.s; });
    let P = 0;
    for(const r of sorted){ if(r.y === 1) P++; }
    const pts = [];
    let tp = 0, fp = 0, ap = 0, prevR = 0;
    for(let i = 0; i < sorted.length; i++){
      if(sorted[i].y === 1) tp++; else fp++;
      if(i === sorted.length - 1 || sorted[i + 1].s !== sorted[i].s){
        const rec = tp / P, prec = tp / (tp + fp);
        ap += (rec - prevR) * prec;
        pts.push({ recall: rec, precision: prec, thr: sorted[i].s });
        prevR = rec;
      }
    }
    return { points: pts, ap: ap, baseline: P / data.length };
  }

  /* Matriz de confusao para um limiar: classe positiva quando s >= limiar */
  function confusion(data, thr){
    let tp = 0, fp = 0, tn = 0, fn = 0;
    for(const r of data){
      const pred = r.s >= thr ? 1 : 0;
      if(pred === 1 && r.y === 1) tp++;
      else if(pred === 1) fp++;
      else if(r.y === 1) fn++;
      else tn++;
    }
    const tpr = tp + fn > 0 ? tp / (tp + fn) : 0;
    const fpr = fp + tn > 0 ? fp / (fp + tn) : 0;
    const prec = tp + fp > 0 ? tp / (tp + fp) : 1;
    const f1 = prec + tpr > 0 ? 2 * prec * tpr / (prec + tpr) : 0;
    return { tp: tp, fp: fp, tn: tn, fn: fn, tpr: tpr, fpr: fpr, precision: prec, recall: tpr, f1: f1,
      accuracy: (tp + tn) / data.length };
  }

  /* AUC por posto (Mann-Whitney), usada em dobras pequenas */
  function aucRank(data){
    return rocCurve(data).auc;
  }

  function mean(a){ let s = 0; for(const v of a) s += v; return a.length ? s / a.length : 0; }
  function sd(a){
    if(a.length < 2) return 0;
    const m = mean(a); let s = 0;
    for(const v of a) s += (v - m) * (v - m);
    return Math.sqrt(s / (a.length - 1));
  }

  /* Formatacao brasileira */
  function fmt(v, d){
    return Number(v).toLocaleString('pt-BR', { minimumFractionDigits: d, maximumFractionDigits: d });
  }
  function pct(v, d){ return fmt(100 * v, d === undefined ? 1 : d) + '%'; }

  /* Fabrica de graficos SVG com escalas lineares */
  function plot(opts){
    const W = opts.width || 320, H = opts.height || 260;
    const m = { l: 44, r: 12, t: 14, b: 38 };
    const x0 = opts.xmin, x1 = opts.xmax, y0 = opts.ymin, y1 = opts.ymax;
    const sx = function(v){ return m.l + (v - x0) / (x1 - x0) * (W - m.l - m.r); };
    const sy = function(v){ return H - m.b - (v - y0) / (y1 - y0) * (H - m.t - m.b); };
    const parts = [];
    parts.push('<rect x="' + m.l + '" y="' + m.t + '" width="' + (W - m.l - m.r) + '" height="' + (H - m.t - m.b) + '" fill="#14161c" stroke="#2e3340"/>');
    const ticks = opts.ticks || 5;
    for(let i = 0; i <= ticks; i++){
      const xv = x0 + (x1 - x0) * i / ticks, yv = y0 + (y1 - y0) * i / ticks;
      parts.push('<line x1="' + sx(xv) + '" y1="' + m.t + '" x2="' + sx(xv) + '" y2="' + (H - m.b) + '" stroke="#262a35"/>');
      parts.push('<line x1="' + m.l + '" y1="' + sy(yv) + '" x2="' + (W - m.r) + '" y2="' + sy(yv) + '" stroke="#262a35"/>');
      parts.push('<text x="' + sx(xv) + '" y="' + (H - m.b + 14) + '" fill="#94a3b8" font-size="10" text-anchor="middle">' + fmt(xv, opts.xdec === undefined ? 1 : opts.xdec) + '</text>');
      if(!opts.hideY) parts.push('<text x="' + (m.l - 5) + '" y="' + (sy(yv) + 3) + '" fill="#94a3b8" font-size="10" text-anchor="end">' + fmt(yv, opts.ydec === undefined ? 1 : opts.ydec) + '</text>');
    }
    parts.push('<text x="' + ((m.l + W - m.r) / 2) + '" y="' + (H - 6) + '" fill="#9cdcfe" font-size="11" text-anchor="middle">' + (opts.xlab || '') + '</text>');
    parts.push('<text x="12" y="' + ((m.t + H - m.b) / 2) + '" fill="#9cdcfe" font-size="11" text-anchor="middle" transform="rotate(-90 12 ' + ((m.t + H - m.b) / 2) + ')">' + (opts.ylab || '') + '</text>');
    return {
      sx: sx, sy: sy, W: W, H: H, parts: parts,
      line: function(pts, color, width, dash){
        if(!pts.length) return;
        const d = pts.map(function(p, i){ return (i ? 'L' : 'M') + sx(p[0]).toFixed(1) + ' ' + sy(p[1]).toFixed(1); }).join(' ');
        parts.push('<path d="' + d + '" fill="none" stroke="' + color + '" stroke-width="' + (width || 2) + '"' + (dash ? ' stroke-dasharray="' + dash + '"' : '') + '/>');
      },
      area: function(pts, color){
        if(!pts.length) return;
        let d = 'M' + sx(pts[0][0]) + ' ' + sy(y0);
        for(const p of pts) d += ' L' + sx(p[0]).toFixed(1) + ' ' + sy(p[1]).toFixed(1);
        d += ' L' + sx(pts[pts.length - 1][0]) + ' ' + sy(y0) + ' Z';
        parts.push('<path d="' + d + '" fill="' + color + '" stroke="none"/>');
      },
      dot: function(x, y, color, r){
        parts.push('<circle cx="' + sx(x) + '" cy="' + sy(y) + '" r="' + (r || 5) + '" fill="' + color + '" stroke="#0f1116" stroke-width="1.5"/>');
      },
      vline: function(x, color, label){
        parts.push('<line x1="' + sx(x) + '" y1="' + m.t + '" x2="' + sx(x) + '" y2="' + (H - m.b) + '" stroke="' + color + '" stroke-width="2" stroke-dasharray="5,3"/>');
        if(label) parts.push('<text x="' + (sx(x) + 4) + '" y="' + (m.t + 12) + '" fill="' + color + '" font-size="10">' + label + '</text>');
      },
      text: function(x, y, txt, color, anchor){
        parts.push('<text x="' + sx(x) + '" y="' + sy(y) + '" fill="' + (color || '#cbd5e1') + '" font-size="10.5" text-anchor="' + (anchor || 'start') + '">' + txt + '</text>');
      },
      svg: function(){
        return '<svg viewBox="0 0 ' + W + ' ' + H + '" width="100%" role="img">' + parts.join('') + '</svg>';
      }
    };
  }

  /* Histograma suavizado (densidade por classe) */
  function histogram(values, lo, hi, bins){
    const h = new Array(bins).fill(0);
    const w = (hi - lo) / bins;
    for(const v of values){
      const k = Math.floor((v - lo) / w);
      if(k >= 0 && k < bins) h[k]++;
    }
    const total = values.length * w;
    return h.map(function(c, i){ return [lo + (i + 0.5) * w, total > 0 ? c / total : 0]; });
  }

  /* Comunicacao de altura com a pagina hospedeira */
  function autoResize(id){
    function send(){
      try{
        if(window.parent && window.parent !== window){
          window.parent.postMessage({ type: 'pf-widget-resize', id: id, height: Math.ceil(document.body.getBoundingClientRect().height) }, '*');
        }
      }catch(e){}
    }
    if(typeof ResizeObserver !== 'undefined') new ResizeObserver(send).observe(document.body);
    window.addEventListener('load', send);
    window.addEventListener('resize', send);
    return send;
  }

  /* Liga um controle deslizante a um rotulo formatado */
  function bindRange(id, fmtFn, onChange){
    const el = document.getElementById(id);
    const out = document.getElementById(id + '-val');
    const update = function(){ if(out) out.textContent = fmtFn(Number(el.value)); onChange(); };
    el.addEventListener('input', update);
    if(out) out.textContent = fmtFn(Number(el.value));
    return function(){ return Number(el.value); };
  }

  global.PF = {
    makeRng: makeRng, makeNormal: makeNormal, phi: phi, binormal: binormal,
    rocCurve: rocCurve, prCurve: prCurve, confusion: confusion, aucRank: aucRank,
    mean: mean, sd: sd, fmt: fmt, pct: pct, plot: plot, histogram: histogram,
    autoResize: autoResize, bindRange: bindRange,
    COLORS: { pos: '#ce9178', neg: '#4ec9b0', accent: '#feca57', blue: '#569cd6', muted: '#64748b' }
  };
})(window);
