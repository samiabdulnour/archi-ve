// archi-glyphs-v2.jsx
// Refined pictograms for Typology / Concept / Element.
// 48×48 viewBox · 1.5 stroke for primary, 0.8 for detail.
// Aesthetic: small architectural drawings — measured, drafted,
// with silhouette + interior detail rather than flat shapes.

const G_SIZE = 44; // render size — slightly larger than the old 40
const G_VB = 48;

const _stroke = (color) => ({
  stroke: color, strokeWidth: 1.5, fill: 'none',
  strokeLinecap: 'round', strokeLinejoin: 'round'
});
const _hair = (color, w = 0.8) => ({ stroke: color, strokeWidth: w, fill: 'none' });

// =====================================================================
// TYPOLOGY  ·  building silhouettes in elevation
// =====================================================================
const typologyGlyphV2 = (name, color = 'currentColor') => {
  const S = _stroke(color);
  const map = {
    Residential:
    <g>
        <path d="M7 24 L24 9 L41 24" {...S} />
        <path d="M11 22 V41 H37 V22" {...S} />
        <rect x="21" y="29" width="6" height="12" {...S} />
        <rect x="14" y="26" width="5" height="5" {...S} />
        <rect x="29" y="26" width="5" height="5" {...S} />
        <path d="M32 14 V19" {...S} />
      </g>,

    Office:
    <g>
        <path d="M10 7 H38 V41 H10 Z" {...S} />
        {[11, 17, 23, 29, 35].map((y) =>
      <g key={y}>
            <line x1="13" y1={y + 1} x2="35" y2={y + 1} {..._hair(color, 0.6)} opacity="0.4" />
            {[14, 20, 26, 32].map((x) =>
        <rect key={x} x={x} y={y - 1} width="2" height="2" fill={color} />
        )}
          </g>
      )}
      </g>,

    Cultural:
    <g>
        <path d="M5 18 L24 7 L43 18 Z" {...S} />
        <line x1="5" y1="40" x2="43" y2="40" {...S} />
        <line x1="6" y1="36" x2="42" y2="36" {...S} />
        {[10, 18, 26, 34].map((x) =>
      <g key={x}>
            <line x1={x + 2} y1="20" x2={x + 2} y2="36" {...S} />
            <line x1={x} y1="20" x2={x + 5} y2="20" {...S} />
            <line x1={x - 1} y1="36" x2={x + 6} y2="36" {...S} />
          </g>
      )}
      </g>,

    Educational:
    <g>
        <path d="M7 18 H41 V41 H7 Z" {...S} />
        <path d="M19 18 V8 H29 V18" {...S} />
        <circle cx="24" cy="13" r="2.4" {...S} />
        <line x1="24" y1="11" x2="24" y2="13" {...S} />
        <line x1="24" y1="13" x2="25.4" y2="13" {...S} />
        <path d="M11 30 V26 Q14 23 17 26 V30 Z" {...S} />
        <path d="M31 30 V26 Q34 23 37 26 V30 Z" {...S} />
        <rect x="22" y="30" width="4" height="11" {...S} />
      </g>,

    Religious:
    <g>
        <path d="M9 22 L24 8 L39 22 V41 H9 Z" {...S} />
        <path d="M24 11 V18 M21 14 H27" {...S} />
        <path d="M21 41 V32 Q24 28 27 32 V41" {...S} />
        <circle cx="24" cy="26" r="2" {...S} />
      </g>,

    Civic:
    <g>
        <path d="M6 41 H42" {...S} />
        <path d="M9 38 H39 V41" {...S} />
        <path d="M11 35 H37" {..._hair(color, 1)} />
        <path d="M16 21 Q24 11 32 21" {...S} />
        <path d="M22 13 V11 H26 V13" {...S} />
        <line x1="16" y1="21" x2="16" y2="35" {...S} />
        <line x1="20" y1="21" x2="20" y2="35" {..._hair(color, 1)} />
        <line x1="28" y1="21" x2="28" y2="35" {..._hair(color, 1)} />
        <line x1="32" y1="21" x2="32" y2="35" {...S} />
        <line x1="14" y1="22" x2="34" y2="22" {...S} />
      </g>,

    Commercial:
    <g>
        <rect x="7" y="11" width="34" height="30" {...S} />
        <path d="M7 17 L11 21 L37 21 L41 17" {...S} />
        {[14, 20, 26, 32].map((x) =>
      <line key={x} x1={x} y1="17" x2={x} y2="21" {..._hair(color, 0.8)} />
      )}
        <rect x="21" y="28" width="6" height="13" {...S} />
        <circle cx="25.5" cy="34" r="0.6" fill={color} />
        <rect x="10" y="25" width="9" height="13" {...S} />
        <rect x="29" y="25" width="9" height="13" {...S} />
        <line x1="14.5" y1="25" x2="14.5" y2="38" {..._hair(color, 0.6)} />
        <line x1="33.5" y1="25" x2="33.5" y2="38" {..._hair(color, 0.6)} />
      </g>,

    Hospitality:
    <g>
        <rect x="6" y="9" width="36" height="32" {...S} />
        <line x1="6" y1="14" x2="42" y2="14" {..._hair(color, 1)} />
        {[16, 22, 28, 34].map((y) =>
      <g key={y}>
            {[10, 17, 24, 31, 38].map((x) =>
        <rect key={x} x={x} y={y} width="5" height="3" {..._hair(color, 0.9)} />
        )}
          </g>
      )}
      </g>,

    Industrial:
    <g>
        <path d="M5 22 L11 14 L11 22 L17 14 L17 22 L23 14 L23 22 L29 14 L29 22 L35 14 L35 22 L41 14 L41 41 L5 41 Z" {...S} />
        <rect x="35" y="4" width="3" height="14" {...S} />
        <line x1="35" y1="8" x2="38" y2="8" {..._hair(color, 0.8)} />
        <rect x="21" y="32" width="6" height="9" {...S} />
      </g>,

    Heritage:
    <g>
        <path d="M14 11 H34 V14 H14 Z" {...S} />
        <path d="M16 14 V35 H32 V14" {...S} />
        <path d="M11 35 H37 V38 H11 Z" {...S} />
        <path d="M9 38 H39 V41 H9 Z" {...S} />
        {[20, 24, 28].map((x) =>
      <line key={x} x1={x} y1="15" x2={x} y2="34" {..._hair(color, 0.7)} opacity="0.7" />
      )}
        <circle cx="19" cy="12.5" r="0.7" fill={color} />
        <circle cx="29" cy="12.5" r="0.7" fill={color} />
      </g>,

    Other:
    <g>
        <circle cx="24" cy="24" r="14" {...S} />
        <text x="24" y="30" textAnchor="middle" fill={color}
        fontSize="18" fontFamily="Inter" fontWeight="500">?</text>
      </g>

  };
  return (
    <svg width={G_SIZE} height={G_SIZE} viewBox={`0 0 ${G_VB} ${G_VB}`}>{map[name] || null}</svg>);

};

// =====================================================================
// CONCEPT  ·  abstract architectural ideas
// =====================================================================
const conceptGlyphV2 = (name, color = 'currentColor') => {
  const S = _stroke(color);
  const map = {
    Form:
    <g>
        <path d="M24 6 L40 14 L40 32 L24 40 L8 32 L8 14 Z" {...S} />
        <path d="M24 6 L24 24 M24 24 L8 14 M24 24 L40 14" {...S} />
      </g>,

    Space:
    <g>
        <rect x="7" y="7" width="34" height="34" {...S} />
        <rect x="14" y="14" width="20" height="20" {...S} />
        <line x1="14" y1="22" x2="14" y2="26" stroke={color} strokeWidth="3" />
        <line x1="7" y1="22" x2="7" y2="26" stroke={color} strokeWidth="3" />
      </g>,

    Light:
    <g>
        <circle cx="24" cy="24" r="6" {...S} />
        {Array.from({ length: 8 }, (_, i) => i * 45).map((a) => {
        const r = a * Math.PI / 180;
        const x1 = 24 + Math.cos(r) * 11,y1 = 24 + Math.sin(r) * 11;
        const x2 = 24 + Math.cos(r) * 16,y2 = 24 + Math.sin(r) * 16;
        return <line key={a} x1={x1} y1={y1} x2={x2} y2={y2} {...S} />;
      })}
      </g>,

    Materiality:
    <g>
        <rect x="8" y="8" width="32" height="32" {...S} />
        <line x1="24" y1="8" x2="24" y2="40" {...S} />
        <line x1="8" y1="24" x2="40" y2="24" {...S} />
        {/* TL · concrete dots */}
        <g fill={color}>
          <circle cx="12" cy="12" r="0.7" /><circle cx="16" cy="14" r="0.6" />
          <circle cx="20" cy="11" r="0.6" /><circle cx="14" cy="18" r="0.6" />
          <circle cx="20" cy="20" r="0.7" /><circle cx="11" cy="22" r="0.6" />
          <circle cx="17" cy="22" r="0.5" />
        </g>
        {/* TR · brick */}
        <g {..._hair(color, 0.8)}>
          <line x1="25" y1="12" x2="39" y2="12" />
          <line x1="25" y1="16" x2="39" y2="16" />
          <line x1="25" y1="20" x2="39" y2="20" />
          <line x1="29" y1="9" x2="29" y2="12" />
          <line x1="34" y1="12" x2="34" y2="16" />
          <line x1="29" y1="16" x2="29" y2="20" />
          <line x1="34" y1="20" x2="34" y2="23" />
        </g>
        {/* BL · timber grain */}
        <g {..._hair(color, 0.8)}>
          <path d="M9 28 Q14 27 19 28 T23 28" />
          <path d="M9 32 Q14 33 19 32 T23 32" />
          <path d="M9 36 Q14 35 19 36 T23 36" />
        </g>
        {/* BR · steel diagonals */}
        <g {..._hair(color, 0.8)}>
          <line x1="26" y1="38" x2="38" y2="26" />
          <line x1="26" y1="32" x2="32" y2="26" />
          <line x1="32" y1="38" x2="38" y2="32" />
        </g>
      </g>,

    Structure:
    <g>
        <line x1="5" y1="16" x2="43" y2="16" {...S} />
        <line x1="5" y1="30" x2="43" y2="30" {...S} />
        <line x1="5" y1="16" x2="5" y2="30" {...S} />
        <line x1="43" y1="16" x2="43" y2="30" {...S} />
        <path d="M5 30 L12 16 L19 30 L26 16 L33 30 L40 16 L43 30" {...S} />
        {/* node dots */}
        {[5, 19, 33].map((x) => <circle key={'b' + x} cx={x} cy="30" r="1.2" fill={color} />)}
        {[12, 26, 40].map((x) => <circle key={'t' + x} cx={x} cy="16" r="1.2" fill={color} />)}
      </g>,

    Context:
    <g>
        <rect x="6" y="6" width="36" height="36" {..._hair(color, 0.7)} opacity="0.5" />
        <line x1="6" y1="22" x2="42" y2="22" {..._hair(color, 0.8)} />
        <line x1="22" y1="6" x2="22" y2="42" {..._hair(color, 0.8)} />
        <rect x="9" y="9" width="9" height="6" fill={color} />
        <rect x="11" y="26" width="8" height="11" fill={color} />
        <rect x="26" y="11" width="13" height="7" fill={color} />
        <rect x="29" y="28" width="6" height="6" fill={color} />
      </g>,

    Circulation:
    <g>
        <path d="M6 36 Q14 36 18 30 Q22 24 26 22 Q32 20 36 14" {...S} />
        <path d="M33 13 L38 12 L37 17" {...S} />
        <circle cx="9" cy="36" r="1.6" fill={color} />
        <circle cx="38" cy="11" r="1.6" fill={color} />
      </g>,

    Craft:
    <g>
        {/* stone block with chisel scoring — the act of making */}
        <rect x="6" y="13" width="36" height="22" {...S} />
        <g {..._hair(color, 0.6)} opacity="0.85">
          {[16, 19, 22, 25, 28, 31].map((y, r) =>
        Array.from({ length: 9 }, (_, c) => {
          const x = 9 + c * 3.5 + r % 2 * 1.75;
          return <line key={r + '-' + c} x1={x} y1={y} x2={x + 1.2} y2={y + 1.2} />;
        })
        ).flat()}
        </g>
      </g>

  };
  return (
    <svg width={G_SIZE} height={G_SIZE} viewBox={`0 0 ${G_VB} ${G_VB}`}>{map[name] || null}</svg>);

};

// =====================================================================
// ELEMENT  ·  architectural parts as detail symbols
// =====================================================================
const elementGlyphV2 = (name, color = 'currentColor') => {
  const S = _stroke(color);
  const paperFill = typeof C !== 'undefined' && C.paper || '#F2EEE6';
  const map = {
    Column:
    <g>
        <path d="M11 12 H37 V15 H11 Z" {...S} />
        <path d="M14 9 H34 V12 H14 Z" {...S} />
        <path d="M16 15 V35 H32 V15" {...S} />
        <line x1="20" y1="16" x2="20" y2="34" {..._hair(color, 0.7)} />
        <line x1="24" y1="16" x2="24" y2="34" {..._hair(color, 0.7)} />
        <line x1="28" y1="16" x2="28" y2="34" {..._hair(color, 0.7)} />
        <path d="M11 35 H37 V38 H11 Z" {...S} />
        <path d="M9 38 H39 V41 H9 Z" {...S} />
      </g>,

    Wall:
    <g>
        {/* poché plan view of a wall */}
        <path d="M13 6 V42 H35 V6 Z" {...S} />
        {[
        [13, 12, 19, 6], [13, 18, 25, 6], [13, 24, 31, 6], [13, 30, 35, 8],
        [13, 36, 35, 14], [13, 42, 35, 20], [19, 42, 35, 26], [25, 42, 35, 32], [31, 42, 35, 38]].
        map(([x1, y1, x2, y2], i) =>
        <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} {..._hair(color, 0.7)} opacity="0.7" />
        )}
      </g>,

    Arch:
    <g>
        <rect x="9" y="22" width="6" height="19" {...S} />
        <rect x="33" y="22" width="6" height="19" {...S} />
        <path d="M9 22 Q9 7 24 7 Q39 7 39 22" {...S} />
        <path d="M15 22 Q15 13 24 13 Q33 13 33 22" {...S} />
        {[-60, -30, 0, 30, 60].map((a) => {
        const r = a * Math.PI / 180;
        const x1 = 24 + Math.sin(r) * 9,y1 = 22 - Math.cos(r) * 9;
        const x2 = 24 + Math.sin(r) * 15,y2 = 22 - Math.cos(r) * 15;
        return <line key={a} x1={x1} y1={y1} x2={x2} y2={y2} {..._hair(color, 1)} />;
      })}
      </g>,

    Door:
    <g>
        <path d="M11 9 V41 M37 9 V41 M11 9 H37" {...S} />
        <rect x="13" y="11" width="22" height="30" {...S} />
        <rect x="16" y="14" width="16" height="9" {..._hair(color, 1)} />
        <rect x="16" y="26" width="16" height="13" {..._hair(color, 1)} />
        <circle cx="32" cy="29" r="0.9" fill={color} />
      </g>,

    Window:
    <g>
        <rect x="9" y="10" width="30" height="28" {...S} />
        <path d="M7 38 H41" {...S} />
        <line x1="24" y1="10" x2="24" y2="38" {...S} />
        <line x1="9" y1="24" x2="39" y2="24" {...S} />
        <line x1="16" y1="10" x2="16" y2="24" {..._hair(color, 0.8)} />
        <line x1="32" y1="10" x2="32" y2="24" {..._hair(color, 0.8)} />
      </g>,

    Stair:
    <g>
        <path d="M6 41 V32 H12 V26 H18 V20 H24 V14 H30 V8 H42" {...S} />
        <line x1="6" y1="41" x2="42" y2="41" {...S} />
        <path d="M9 30 L33 6" {..._hair(color, 0.8)} />
        <line x1="9" y1="32" x2="9" y2="30" {..._hair(color, 0.8)} />
        <line x1="33" y1="8" x2="33" y2="6" {..._hair(color, 0.8)} />
      </g>,

    Ramp:
    <g>
        <path d="M6 41 L42 9" {...S} />
        <line x1="6" y1="41" x2="42" y2="41" {...S} />
        <line x1="42" y1="9" x2="42" y2="41" {...S} />
        <path d="M10 36 L40 9" {..._hair(color, 0.8)} />
        {[14, 22, 30, 38].map((x, i) => {
        const y = 41 - (x - 6) * 32 / 36;
        return <line key={i} x1={x} y1={y} x2={x} y2={y - 5} {..._hair(color, 0.8)} />;
      })}
      </g>,

    Roof:
    <g>
        <path d="M5 28 L24 8 L43 28" {...S} />
        <path d="M9 28 L24 12 L39 28" {..._hair(color, 1)} />
        <line x1="5" y1="28" x2="43" y2="28" {...S} />
        <line x1="5" y1="32" x2="43" y2="32" {...S} />
        {[12, 17, 22, 27, 32, 37].map((x) => {
        const top_y = 28 - (1 - Math.abs(x - 24) / 19) * 16;
        return <line key={x} x1={x} y1={top_y} x2={x} y2="28" {..._hair(color, 0.7)} />;
      })}
      </g>,

    Ceiling:
    <g>
        {/* coffered ceiling — 1pt perspective */}
        <path d="M6 6 H42 V42 H6 Z" {...S} />
        <path d="M14 14 H34 V34 H14 Z" {..._hair(color, 1)} />
        <path d="M6 6 L14 14 M42 6 L34 14 M6 42 L14 34 M42 42 L34 34" {..._hair(color, 1)} />
        <line x1="20.7" y1="14" x2="20.7" y2="34" {..._hair(color, 0.7)} />
        <line x1="27.3" y1="14" x2="27.3" y2="34" {..._hair(color, 0.7)} />
        <line x1="14" y1="20.7" x2="34" y2="20.7" {..._hair(color, 0.7)} />
        <line x1="14" y1="27.3" x2="34" y2="27.3" {..._hair(color, 0.7)} />
      </g>,

    Floor:
    <g>
        <line x1="6" y1="20" x2="42" y2="20" {...S} />
        <line x1="6" y1="34" x2="42" y2="34" {...S} />
        <line x1="6" y1="24" x2="42" y2="24" {..._hair(color, 0.6)} opacity="0.7" />
        <line x1="6" y1="29" x2="42" y2="29" {..._hair(color, 0.6)} opacity="0.7" />
        {Array.from({ length: 9 }, (_, i) => i * 4 + 8).map((x) =>
      <line key={x} x1={x} y1="29" x2={x - 4} y2="34" {..._hair(color, 0.6)} />
      )}
        {/* finish — flooring tiles on top */}
        <line x1="14" y1="20" x2="14" y2="24" {..._hair(color, 0.6)} />
        <line x1="22" y1="20" x2="22" y2="24" {..._hair(color, 0.6)} />
        <line x1="30" y1="20" x2="30" y2="24" {..._hair(color, 0.6)} />
        <line x1="38" y1="20" x2="38" y2="24" {..._hair(color, 0.6)} />
      </g>,

    Facade:
    <g>
        <path d="M8 6 H40 V42 H8 Z" {...S} />
        {[10, 19, 28].map((y) =>
      [11, 21, 31].map((x) =>
      <rect key={x + '-' + y} x={x} y={y} width="6" height="7" {..._hair(color, 1)} />
      )
      )}
        <line x1="6" y1="42" x2="42" y2="42" {...S} />
        {/* string courses */}
        <line x1="8" y1="18" x2="40" y2="18" {..._hair(color, 0.6)} opacity="0.5" />
        <line x1="8" y1="27" x2="40" y2="27" {..._hair(color, 0.6)} opacity="0.5" />
      </g>,

    Railing:
    <g>
        <line x1="6" y1="14" x2="42" y2="14" {...S} />
        <line x1="6" y1="17" x2="42" y2="17" {..._hair(color, 1)} />
        <line x1="6" y1="36" x2="42" y2="36" {...S} />
        {[10, 16, 22, 28, 34, 40].map((x) =>
      <line key={x} x1={x} y1="17" x2={x} y2="36" {..._hair(color, 1)} />
      )}
        <line x1="4" y1="38" x2="44" y2="38" {...S} />
      </g>,

    Joint:
    <g>
        <rect x="8" y="20" width="32" height="8" {...S} />
        <rect x="20" y="8" width="8" height="32" {...S} />
        <circle cx="24" cy="24" r="5" {..._hair(color, 1.2)} fill={paperFill} />
        <text x="24" y="26" textAnchor="middle" fontSize="5"
        fill={color} fontFamily="Inter" fontWeight="600">A</text>
      </g>,

    Pavement:
    <g>
        <rect x="6" y="6" width="36" height="36" {...S} />
        {[12, 18, 24, 30, 36].map((y) =>
      <line key={y} x1="6" y1={y} x2="42" y2={y} {..._hair(color, 0.8)} />
      )}
        {[
        [14, 6], [22, 6], [30, 6], [38, 6],
        [10, 12], [18, 12], [26, 12], [34, 12],
        [14, 18], [22, 18], [30, 18], [38, 18],
        [10, 24], [18, 24], [26, 24], [34, 24],
        [14, 30], [22, 30], [30, 30], [38, 30],
        [10, 36], [18, 36], [26, 36], [34, 36]].
        map(([x, y], i) =>
        <line key={i} x1={x} y1={y} x2={x} y2={y + 6} {..._hair(color, 0.8)} />
        )}
      </g>

  };
  return (
    <svg width={G_SIZE} height={G_SIZE} viewBox={`0 0 ${G_VB} ${G_VB}`}>{map[name] || null}</svg>);

};

Object.assign(window, { typologyGlyphV2, conceptGlyphV2, elementGlyphV2 });
