/**
 * Fragment-driven D3 scene for the DoWEA leadership deck.
 *
 * One scene, time across and grade up: a cohort of stick-figure students
 * walks the 2025 Grade 3 year (lower left), is snapshotted in the spring
 * (status), travels the diagonal into the 2026 Grade 4 year (upper right),
 * is snapshotted again, and the flow between the two snapshots is growth.
 *
 * Hosts declare:
 *   data-scene="cohort" | "peers"   (peers = the same scene, Section 5)
 *   data-step="N"                   starting / static step
 *   data-fragment-steps="1,2,3"     steps advanced by successive fragments
 *
 * Steps:
 *   0 frame · 1 enter Grade 3 · 2 walk the year · 3 spring 2025 status rail
 *   4 travel to Grade 4 and walk the year · 5 spring 2026 status rail
 *   6 growth ribbons · 7 colored by growth percentile · 8 status row vs
 *   growth diagonal · 9 one band of academic peers · 10 one student's SGP
 *
 * Every step is a complete state, so fragments reverse cleanly and slide
 * entry jumps straight to the state. prefers-reduced-motion removes motion.
 */
(function () {
  'use strict';

  var REDUCE = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var EASE = d3.easeCubicInOut;

  var INK = '#141410';
  var GREY = '#7c7c7c';
  var BLUE = '#3498DB';
  var ORANGE = '#E67E22';
  var RIBBON_GREY = '#a4a49c';

  function ms(n) {
    return REDUCE ? 0 : n;
  }

  function rng(seed) {
    var s = seed;
    return function () {
      s = (s * 1664525 + 1013904223) >>> 0;
      return s / 4294967296;
    };
  }

  function normal(rand) {
    var u = 1 - rand();
    var v = rand();
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  }

  /** Standard normal CDF (Zelen & Severo, |error| < 7.5e-8). */
  function phi(x) {
    var t = 1 / (1 + 0.2316419 * Math.abs(x));
    var d = 0.3989422804014327 * Math.exp(-x * x / 2);
    var p = d * t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 +
      t * (-1.821255978 + t * 1.330274429))));
    return x > 0 ? 1 - p : p;
  }

  function clamp(x, lo, hi) {
    return x < lo ? lo : x > hi ? hi : x;
  }

  /* ── Synthetic cohort ────────────────────────────────────────────
   * Gaussian copula with rho = 0.75. Under it the growth percentile is
   * exactly Phi(e), the student's standing among peers with the same
   * prior score, so the colors carry a true SGP rather than decoration.
   */
  var RHO = 0.75;
  var N = 36;

  function makeCohort() {
    var rand = rng(20261026);
    var out = [];
    for (var i = 0; i < N; i++) {
      var z1 = normal(rand);
      var e = normal(rand);
      out.push({
        id: i,
        z1: z1,
        z2: RHO * z1 + Math.sqrt(1 - RHO * RHO) * e,
        sgp: clamp(Math.round(100 * phi(e)), 1, 99),
        jit: rand()
      });
    }
    out.slice().sort(function (a, b) { return a.z1 - b.z1; })
      .forEach(function (d, r) { d.col1 = r % 3; d.rank1 = r; });
    out.slice().sort(function (a, b) { return a.z2 - b.z2; })
      .forEach(function (d, r) { d.col2 = r % 3; });
    out.forEach(function (d) {
      d.peer = d.rank1 >= N / 2 - 5 && d.rank1 < N / 2 + 4;
    });
    var peers = out.filter(function (d) { return d.peer; });
    var focal = peers.slice().sort(function (a, b) {
      return Math.abs(a.sgp - 70) - Math.abs(b.sgp - 70);
    })[0];
    focal.focal = true;
    return out;
  }

  var STUDENTS = makeCohort();
  var FOCAL = STUDENTS.filter(function (d) { return d.focal; })[0];

  function otherCohort(seed) {
    var rand = rng(seed);
    var zs = [];
    for (var i = 0; i < N; i++) zs.push(normal(rand));
    return zs;
  }

  var OTHER_G4_2025 = otherCohort(4025);
  var OTHER_G3_2026 = otherCohort(3026);

  var growthColor = d3.interpolateRgbBasis(
    ['#B03A2E', '#E67E22', '#B4B4AC', '#5DADE2', '#1A5276']
  );

  function sgpColor(d) {
    return growthColor(d.sgp / 100);
  }

  /* ── Geometry (fixed viewBox) ──────────────────────────────────── */

  var VB_W = 1600;
  var VB_H = 720;
  var COLS = [{ x0: 170, x1: 810 }, { x0: 890, x1: 1530 }];
  var ROWS = { g4: { y0: 20, y1: 280 }, g3: { y0: 330, y1: 590 } };
  var RAIL_H = 220;
  var RAIL_W = 26;
  var SUMMER_X = (COLS[0].x1 + COLS[1].x0) / 2;

  function cell(col, row) {
    var c = COLS[col];
    var r = ROWS[row];
    return {
      x0: c.x0, x1: c.x1, y0: r.y0, y1: r.y1,
      cx: (c.x0 + c.x1) / 2, cy: (r.y0 + r.y1) / 2,
      railX: c.x1 - 54
    };
  }

  var C25 = cell(0, 'g3');
  var C26 = cell(1, 'g4');
  var X25 = cell(0, 'g4');
  var X26 = cell(1, 'g3');

  function yz(c, z) {
    return c.cy - clamp(z, -2.4, 2.4) / 2.4 * (RAIL_H / 2 - 10);
  }

  function figurePos(d, step) {
    if (step <= 1) {
      return {
        x: C25.x0 + 40 + (d.id % 6) * 17,
        y: C25.cy + (Math.floor(d.id / 6) - 2.5) * 26
      };
    }
    if (step === 2) return { x: C25.railX - 70 - d.jit * 70, y: yz(C25, d.z1) };
    if (step === 3) return { x: C25.railX - RAIL_W / 2 - 12 - d.col1 * 15, y: yz(C25, d.z1) };
    if (step === 4) return { x: C26.railX - 70 - d.jit * 70, y: yz(C26, d.z2) };
    return { x: C26.railX - RAIL_W / 2 - 12 - d.col2 * 15, y: yz(C26, d.z2) };
  }

  /** Spring 2025 rail → August of Grade 4 at the prior position → May. */
  function travelD(d) {
    var p0 = figurePos(d, 3);
    var pm = { x: C26.x0 + 40, y: yz(C26, d.z1) };
    var p1 = figurePos(d, 4);
    var k1 = 0.45 * (pm.x - p0.x);
    var k2 = 0.42 * (p1.x - pm.x);
    return 'M' + p0.x + ',' + p0.y +
      'C' + (p0.x + k1) + ',' + p0.y + ' ' + (pm.x - k1) + ',' + pm.y + ' ' + pm.x + ',' + pm.y +
      'C' + (pm.x + k2) + ',' + pm.y + ' ' + (p1.x - k2) + ',' + p1.y + ' ' + p1.x + ',' + p1.y;
  }

  function ribbonEnds(d) {
    return {
      x1: C25.railX + RAIL_W / 2, y1: yz(C25, d.z1),
      x2: C26.railX - RAIL_W / 2, y2: yz(C26, d.z2)
    };
  }

  function ribbonD(d) {
    var e = ribbonEnds(d);
    var k = 0.42 * (e.x2 - e.x1);
    return 'M' + e.x1 + ',' + e.y1 +
      'C' + (e.x1 + k) + ',' + e.y1 + ' ' + (e.x2 - k) + ',' + e.y2 + ' ' + e.x2 + ',' + e.y2;
  }

  var CAPTIONS = [
    'Time runs left to right. Grade runs bottom to top.',
    'In August 2025 a cohort of students starts Grade 3.',
    'They learn across the school year — and they do not all learn the same things.',
    'Spring snapshot. Status: what students know and can do at a fixed point in time.',
    'Over the summer they move up a grade and spend 2025–26 in Grade 4.',
    'Spring snapshot again. Status: what they know and can do in spring 2026.',
    'Growth: the change in what students know and can do across time — the same students, followed.',
    'Growth percentile: each student’s progress compared with peers who started in the same place.',
    'Status compares across a row — different students. Growth follows the diagonal — the same students.',
    'Academic peers: students who started in the same place. They do not all finish in the same place.',
    'A growth percentile locates one student among those peers.'
  ];

  /* ── Build ─────────────────────────────────────────────────────── */

  function text(g, x, y, str, opts) {
    opts = opts || {};
    return g.append('text')
      .attr('x', x).attr('y', y)
      .attr('text-anchor', opts.anchor || 'start')
      .attr('fill', opts.fill || GREY)
      .attr('font-family', opts.family || 'Noto Sans, sans-serif')
      .attr('font-size', opts.size || 18)
      .attr('font-weight', opts.weight || 400)
      .text(str);
  }

  function rail(g, c, label, cls) {
    var r = g.append('g').attr('class', 'status-rail ' + (cls || ''));
    r.append('rect')
      .attr('x', c.railX - RAIL_W / 2).attr('y', c.cy - RAIL_H / 2)
      .attr('width', RAIL_W).attr('height', RAIL_H).attr('rx', 8);
    text(r, c.railX + RAIL_W / 2, c.cy - RAIL_H / 2 - 8, label,
      { anchor: 'end', fill: ORANGE, size: 19, weight: 600 });
    return r;
  }

  function stick(sel) {
    sel.append('circle').attr('class', 'stick-head').attr('cx', 0).attr('cy', -7).attr('r', 2.8);
    sel.append('line').attr('x1', 0).attr('y1', -4.2).attr('x2', 0).attr('y2', 2.5);
    sel.append('line').attr('class', 'stick-arms').attr('x1', -3.8).attr('y1', -2).attr('x2', 3.8).attr('y2', -2);
    sel.append('line').attr('class', 'leg leg-l').attr('x1', 0).attr('y1', 2.5).attr('x2', -3).attr('y2', 8.5);
    sel.append('line').attr('class', 'leg leg-r').attr('x1', 0).attr('y1', 2.5).attr('x2', 3).attr('y2', 8.5);
  }

  function build(host) {
    var svg = d3.select(host).append('svg')
      .attr('viewBox', '0 0 ' + VB_W + ' ' + VB_H)
      .attr('role', 'img')
      .attr('aria-label', 'A cohort of students moves from Grade 3 in 2025 to Grade 4 in 2026. ' +
        'Spring snapshots show status; the flow between them shows growth.');
    var g = svg.append('g').attr('class', 'root');

    // Frame: four cells, the diagonal two active.
    [[X25, false], [X26, false], [C25, true], [C26, true]].forEach(function (pair) {
      var c = pair[0];
      g.append('rect')
        .attr('class', pair[1] ? 'lattice-cell' : 'lattice-cell lattice-cell--faint')
        .attr('x', c.x0).attr('y', c.y0)
        .attr('width', c.x1 - c.x0).attr('height', c.y1 - c.y0)
        .attr('rx', 16);
    });

    text(g, COLS[0].x0 - 22, (ROWS.g4.y0 + ROWS.g4.y1) / 2 + 8, 'Grade 4',
      { anchor: 'end', fill: BLUE, size: 28, weight: 600, family: 'Josefin Sans, sans-serif' });
    text(g, COLS[0].x0 - 22, (ROWS.g3.y0 + ROWS.g3.y1) / 2 + 8, 'Grade 3',
      { anchor: 'end', fill: BLUE, size: 28, weight: 600, family: 'Josefin Sans, sans-serif' });
    g.append('text')
      .attr('transform', 'translate(34,' + (ROWS.g4.y0 + ROWS.g3.y1) / 2 + ') rotate(-90)')
      .attr('text-anchor', 'middle').attr('fill', GREY)
      .attr('font-family', 'Noto Sans, sans-serif').attr('font-size', 20)
      .text('Grade ↑');

    COLS.forEach(function (c, i) {
      text(g, c.x0 + 10, 614, 'August', { size: 18 });
      text(g, c.x1 - 10, 614, 'May', { anchor: 'end', size: 18 });
      text(g, (c.x0 + c.x1) / 2, 650, i === 0 ? '2025' : '2026',
        { anchor: 'middle', fill: INK, size: 32, weight: 600, family: 'Josefin Sans, sans-serif' });
    });
    text(g, SUMMER_X, 614, 'summer', { anchor: 'middle', size: 17 });
    text(g, SUMMER_X, 650, 'Time →', { anchor: 'middle', size: 20 });

    // Lattice ground (behind ribbons): the cohort diagonal.
    var back = g.append('g').attr('class', 'lattice-back').attr('opacity', 0);
    back.append('line')
      .attr('x1', C25.cx).attr('y1', C25.cy).attr('x2', C26.cx).attr('y2', C26.cy)
      .attr('stroke', BLUE).attr('stroke-opacity', 0.12)
      .attr('stroke-width', 150).attr('stroke-linecap', 'round');

    // Other cohorts, faint (shown at step 8).
    var front = g.append('g').attr('class', 'lattice-front').attr('opacity', 0);
    [[X25, OTHER_G4_2025, 'Spring 2025'], [X26, OTHER_G3_2026, 'Spring 2026']].forEach(function (t) {
      var r = rail(front, t[0], t[2], 'status-rail--faint');
      r.selectAll('circle').data(t[1]).enter().append('circle')
        .attr('cx', t[0].railX).attr('cy', function (z) { return yz(t[0], z); })
        .attr('r', 3).attr('fill', RIBBON_GREY);
    });
    text(front, X25.x0 + 22, X25.y0 + 34, 'Grade 4 in 2025 — a different group of students', { size: 18 });
    text(front, X26.railX - RAIL_W / 2 - 16, X26.y1 - 20, 'Grade 3 in 2026 — a different group of students',
      { anchor: 'end', size: 18 });
    front.append('rect')
      .attr('class', 'status-row-outline')
      .attr('x', COLS[0].x0 - 10).attr('y', ROWS.g4.y0 - 10)
      .attr('width', COLS[1].x1 - COLS[0].x0 + 20).attr('height', ROWS.g4.y1 - ROWS.g4.y0 + 20)
      .attr('rx', 22);

    var rails = g.append('g').attr('class', 'rails');
    rail(rails, C25, 'Spring 2025 snapshot', 'rail-2025').attr('opacity', 0);
    rail(rails, C26, 'Spring 2026 snapshot', 'rail-2026').attr('opacity', 0);

    g.append('g').attr('class', 'ribbons')
      .selectAll('path').data(STUDENTS, function (d) { return d.id; })
      .enter().append('path')
      .attr('class', 'flow-ribbon')
      .attr('d', ribbonD)
      .attr('stroke', RIBBON_GREY)
      .attr('opacity', 0);

    var ends = g.append('g').attr('class', 'ends');
    ['1', '2'].forEach(function (k) {
      ends.selectAll('circle.end' + k).data(STUDENTS, function (d) { return d.id; })
        .enter().append('circle')
        .attr('class', 'end end' + k)
        .attr('cx', function (d) { return ribbonEnds(d)['x' + k]; })
        .attr('cy', function (d) { return ribbonEnds(d)['y' + k]; })
        .attr('r', 3.6).attr('fill', RIBBON_GREY).attr('opacity', 0);
    });

    var guides = g.append('g').attr('class', 'guides').attr('visibility', 'hidden');
    guides.selectAll('path').data(STUDENTS, function (d) { return d.id; })
      .enter().append('path')
      .attr('d', travelD)
      .attr('fill', 'none');

    g.append('g').attr('class', 'students')
      .selectAll('g').data(STUDENTS, function (d) { return d.id; })
      .enter().append('g')
      .attr('class', 'stick')
      .attr('opacity', 0)
      .attr('transform', function (d) {
        var p = figurePos(d, 0);
        this.__pos = p;
        return 'translate(' + p.x + ',' + p.y + ')';
      })
      .call(stick);

    // Peer band and focal student (Section 5).
    var peerTop = d3.min(STUDENTS.filter(function (d) { return d.peer; }), function (d) { return yz(C25, d.z1); });
    var peerBot = d3.max(STUDENTS.filter(function (d) { return d.peer; }), function (d) { return yz(C25, d.z1); });
    var band = g.append('g').attr('class', 'peer-band').attr('opacity', 0);
    band.append('rect')
      .attr('x', C25.railX - RAIL_W / 2 - 8).attr('y', peerTop - 9)
      .attr('width', RAIL_W + 16).attr('height', peerBot - peerTop + 18)
      .attr('rx', 8)
      .attr('fill', BLUE).attr('fill-opacity', 0.12)
      .attr('stroke', BLUE).attr('stroke-width', 2.5);
    text(band, C25.railX - RAIL_W / 2 - 20, (peerTop + peerBot) / 2 - 4, 'Academic peers:',
      { anchor: 'end', fill: BLUE, size: 22, weight: 600 }).attr('class', 'halo');
    text(band, C25.railX - RAIL_W / 2 - 20, (peerTop + peerBot) / 2 + 20, 'the same starting point',
      { anchor: 'end', fill: BLUE, size: 19 }).attr('class', 'halo');

    var fe = ribbonEnds(FOCAL);
    var focal = g.append('g').attr('class', 'focal-label').attr('opacity', 0);
    focal.append('circle').attr('cx', fe.x2).attr('cy', fe.y2).attr('r', 8)
      .attr('fill', 'none').attr('stroke', INK).attr('stroke-width', 2);
    text(focal, fe.x2 - 18, fe.y2 - 14, 'SGP ' + FOCAL.sgp,
      { anchor: 'end', fill: INK, size: 26, weight: 600, family: 'Josefin Sans, sans-serif' }).attr('class', 'halo');
    text(focal, fe.x2 - 18, fe.y2 + 12, 'grew as much as or more than ' + FOCAL.sgp + '% of peers',
      { anchor: 'end', fill: INK, size: 19 }).attr('class', 'halo');

    // Growth percentile legend (step 7+).
    var legend = g.append('g').attr('class', 'sgp-legend').attr('opacity', 0)
      .attr('transform', 'translate(1270,632)');
    var gradId = 'sgp-grad-' + Math.random().toString(36).slice(2, 8);
    var grad = svg.append('defs').append('linearGradient').attr('id', gradId);
    d3.range(0, 1.0001, 0.25).forEach(function (t) {
      grad.append('stop').attr('offset', t).attr('stop-color', growthColor(t));
    });
    legend.append('rect').attr('width', 260).attr('height', 10).attr('rx', 5)
      .attr('fill', 'url(#' + gradId + ')');
    text(legend, 0, 32, 'Low', { size: 18 });
    text(legend, 130, 32, 'Typical', { anchor: 'middle', size: 18 });
    text(legend, 260, 32, 'High', { anchor: 'end', size: 18 });

    g.append('text').attr('class', 'step-caption')
      .attr('x', COLS[0].x0).attr('y', 702)
      .attr('fill', '#4a4a46').attr('font-size', 26)
      .attr('font-family', 'Noto Sans, sans-serif');

    return svg;
  }

  /* ── Apply a step ──────────────────────────────────────────────── */

  var MOVE_MS = { 1: 700, 2: 1800, 3: 900, 4: 3200, 5: 900 };

  function fade(sel, opacity, dur, name) {
    if (!dur) {
      sel.interrupt(name).attr('opacity', opacity);
      return;
    }
    sel.transition(name).duration(dur).attr('opacity', opacity);
  }

  function moveFigures(root, step, prev, dur) {
    var figs = root.selectAll('.students .stick');
    var guides = {};
    root.selectAll('.guides path').each(function (d) { guides[d.id] = this; });
    var mode = 'direct';
    if (prev === 3 && step === 4) mode = 'forward';
    if (prev === 4 && step === 3) mode = 'back';
    var visible = step >= 1 && step <= 5;

    if (!dur) {
      figs.interrupt('move').classed('walking', false)
        .attr('transform', function (d) {
          var p = figurePos(d, step);
          this.__pos = p;
          return 'translate(' + p.x + ',' + p.y + ')';
        });
      fade(figs, visible ? 1 : 0, 0, 'fade');
      return;
    }

    var moveMs = MOVE_MS[Math.max(step, prev)] || 900;
    var moving = step <= 5 && prev <= 5 && step !== prev && !(step <= 1 && prev <= 1);
    if (moving) {
      figs.classed('walking', true)
        .transition('move').duration(ms(moveMs)).ease(EASE)
        .attrTween('transform', function (d) {
          var el = this;
          var from = el.__pos || figurePos(d, prev);
          var to = figurePos(d, step);
          var path = guides[d.id];
          var len = (mode !== 'direct' && path) ? path.getTotalLength() : 0;
          return function (t) {
            var p;
            if (len) {
              var pt = path.getPointAtLength((mode === 'forward' ? t : 1 - t) * len);
              p = { x: pt.x, y: pt.y };
            } else {
              p = { x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t };
            }
            el.__pos = p;
            return 'translate(' + p.x + ',' + p.y + ')';
          };
        })
        .on('end interrupt', function () { d3.select(this).classed('walking', false); });
    } else if (step >= 6 && prev < 6) {
      figs.interrupt('move').classed('walking', false);
    }
    fade(figs, visible ? 1 : 0, dur, 'fade');
  }

  function applyCohort(host, step, instant) {
    var svg = d3.select(host).select('svg');
    var fresh = svg.empty();
    if (fresh) svg = build(host);
    var root = svg.select('.root');
    var prev = host.__step;
    if (!fresh && !instant && prev === step) return;
    var dur = (fresh || instant || prev == null) ? 0 : ms(700);
    if (prev == null || fresh || instant) prev = step;
    host.__step = step;

    moveFigures(root, step, prev, dur);

    fade(root.select('.rail-2025'), step >= 3 ? 1 : 0, dur, 'fade');
    fade(root.select('.rail-2026'), step >= 5 ? 1 : 0, dur, 'fade');

    var peerFocus = step >= 9;
    var ribbons = root.selectAll('.ribbons path');
    var ribbonOpacity = function (d) {
      if (step < 6) return 0;
      if (peerFocus) return d.peer ? 0.95 : 0.07;
      return 0.8;
    };
    var ribbonColor = function (d) { return step >= 7 ? sgpColor(d) : RIBBON_GREY; };
    var endColor = function (d) { return step >= 7 ? sgpColor(d) : '#2e86c1'; };
    var ribbonWidth = function (d) { return step >= 10 && d.focal ? 5 : 2.6; };
    var ends = root.selectAll('.ends circle');
    var endOpacity = function (d) {
      var shown = this.classList.contains('end1') ? step >= 3 : step >= 5;
      if (!shown) return 0;
      if (peerFocus) return d.peer ? 1 : 0.12;
      return 0.95;
    };
    if (dur) {
      ribbons.transition('fade').duration(dur)
        .attr('opacity', ribbonOpacity).attr('stroke', ribbonColor).attr('stroke-width', ribbonWidth);
      ends.transition('fade').duration(dur)
        .attr('opacity', endOpacity).attr('fill', endColor);
    } else {
      ribbons.interrupt('fade')
        .attr('opacity', ribbonOpacity).attr('stroke', ribbonColor).attr('stroke-width', ribbonWidth);
      ends.interrupt('fade').attr('opacity', endOpacity).attr('fill', endColor);
    }

    fade(root.select('.sgp-legend'), step >= 7 ? 1 : 0, dur, 'fade');
    fade(root.select('.lattice-back'), step === 8 ? 1 : 0, dur, 'fade');
    fade(root.select('.lattice-front'), step === 8 ? 1 : 0, dur, 'fade');
    fade(root.selectAll('.lattice-cell--faint'), step === 8 ? 1 : 0.45, dur, 'fade');
    fade(root.select('.peer-band'), peerFocus ? 1 : 0, dur, 'fade');
    fade(root.select('.focal-label'), step >= 10 ? 1 : 0, dur, 'fade');

    root.select('.step-caption').text(CAPTIONS[clamp(step, 0, CAPTIONS.length - 1)]);
  }

  /* ── Reveal wiring ──────────────────────────────────────────── */

  function parseSteps(host) {
    var raw = host.getAttribute('data-fragment-steps');
    if (!raw) return [];
    return raw.split(',').map(function (s) { return parseInt(s.trim(), 10); });
  }

  function currentStep(host) {
    var base = parseInt(host.getAttribute('data-step') || '0', 10);
    var steps = parseSteps(host);
    if (!steps.length) return base;
    var slide = host.closest('section');
    if (!slide || typeof Reveal === 'undefined') return base;
    var idx = Reveal.getIndices().f;
    if (idx == null || idx < 0) return base;
    return steps[Math.min(idx, steps.length - 1)];
  }

  function renderHost(host, instant) {
    if (!host) return;
    var scene = host.getAttribute('data-scene');
    if (scene === 'cohort' || scene === 'peers') applyCohort(host, currentStep(host), instant);
  }

  function renderCurrent(instant) {
    if (typeof Reveal === 'undefined') return;
    var slide = Reveal.getCurrentSlide();
    if (!slide) return;
    slide.querySelectorAll('.scene-host').forEach(function (h) { renderHost(h, instant); });
  }

  function init() {
    renderCurrent(true);
    setTimeout(function () { renderCurrent(true); }, 0);
    Reveal.on('slidechanged', function () {
      renderCurrent(true);
      setTimeout(function () { renderCurrent(true); }, 0);
    });
    Reveal.on('fragmentshown', function () { renderCurrent(false); });
    Reveal.on('fragmenthidden', function () { renderCurrent(false); });
  }

  if (typeof Reveal !== 'undefined' && Reveal.isReady && Reveal.isReady()) {
    init();
  } else if (typeof Reveal !== 'undefined') {
    Reveal.on('ready', init);
  }
})();
