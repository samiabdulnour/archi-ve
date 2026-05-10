// archi-glyphs-showcase.jsx
// Side-by-side compare of old vs refined glyphs, plus tagger context.

const TYPOLOGY_LIST = ['Residential','Office','Cultural','Educational','Religious','Civic','Commercial','Hospitality','Industrial','Heritage','Other'];
const CONCEPT_LIST  = ['Form','Space','Light','Materiality','Structure','Context','Circulation','Craft'];
const ELEMENT_LIST  = ['Column','Wall','Arch','Door','Window','Stair','Ramp','Roof','Ceiling','Floor','Facade','Railing','Joint','Pavement'];

// --- old glyphs from archi-tagger.jsx (40×40 viewBox) -----------------
function OldTypology({ name, color = C.ink }) {
  const m = {
    Residential: <path d="M6 20 L20 6 L34 20 V34 H6 Z" fill={color} />,
    Office: <g fill={color}><rect x="8" y="8" width="24" height="26" /><g fill={C.paper}><rect x="11" y="12" width="4" height="4" /><rect x="18" y="12" width="4" height="4" /><rect x="25" y="12" width="4" height="4" /><rect x="11" y="19" width="4" height="4" /><rect x="18" y="19" width="4" height="4" /><rect x="25" y="19" width="4" height="4" /><rect x="11" y="26" width="4" height="4" /><rect x="25" y="26" width="4" height="4" /></g></g>,
    Cultural: <g fill={color}><polygon points="20,6 36,16 4,16" /><rect x="6" y="16" width="3" height="14" /><rect x="13" y="16" width="3" height="14" /><rect x="24" y="16" width="3" height="14" /><rect x="31" y="16" width="3" height="14" /><rect x="4" y="30" width="32" height="3" /></g>,
    Educational: <g fill={color}><rect x="6" y="14" width="28" height="20" /><polygon points="6,14 20,6 34,14" /><rect x="17" y="22" width="6" height="12" fill={C.paper} /></g>,
    Religious: <g fill={color}><rect x="6" y="20" width="28" height="14" /><path d="M6 20 Q20 6 34 20 Z" /><rect x="18" y="10" width="4" height="10" /><rect x="14" y="14" width="12" height="3" /></g>,
    Civic: <g fill={color}><rect x="6" y="14" width="28" height="20" /><polygon points="6,14 20,6 34,14" /><circle cx="20" cy="22" r="3" fill={C.paper} /></g>,
    Commercial: <g fill={color}><rect x="8" y="10" width="24" height="24" /><rect x="11" y="14" width="6" height="6" fill={C.paper} /><rect x="23" y="14" width="6" height="6" fill={C.paper} /><rect x="11" y="24" width="18" height="2" fill={C.paper} /></g>,
    Hospitality: <g fill={color}><rect x="6" y="12" width="28" height="22" /><rect x="10" y="16" width="3" height="3" fill={C.paper} /><rect x="16" y="16" width="3" height="3" fill={C.paper} /><rect x="22" y="16" width="3" height="3" fill={C.paper} /><rect x="28" y="16" width="3" height="3" fill={C.paper} /><rect x="10" y="22" width="3" height="3" fill={C.paper} /><rect x="16" y="22" width="3" height="3" fill={C.paper} /><rect x="22" y="22" width="3" height="3" fill={C.paper} /><rect x="28" y="22" width="3" height="3" fill={C.paper} /></g>,
    Industrial: <g fill={color}><polygon points="4,34 4,18 12,22 12,14 20,18 20,14 28,18 28,14 36,18 36,34" /></g>,
    Heritage: <g fill={color}><rect x="6" y="14" width="28" height="20" /><polygon points="6,14 20,4 34,14" /><rect x="14" y="20" width="4" height="14" fill={C.paper} /><rect x="22" y="20" width="4" height="14" fill={C.paper} /><circle cx="20" cy="11" r="1.5" fill={C.paper} /></g>,
    Other: <g fill={color}><circle cx="20" cy="20" r="14" /><text x="20" y="26" textAnchor="middle" fill={C.paper} fontSize="16" fontFamily="Inter" fontWeight="600">?</text></g>
  };
  return <svg width="40" height="40" viewBox="0 0 40 40">{m[name]}</svg>;
}

function OldConcept({ name, color = C.ink }) {
  const m = {
    Form: <path d="M8 28 L20 8 L32 28 Z" fill={color} />,
    Space: <rect x="8" y="8" width="24" height="24" stroke={color} strokeWidth="2" fill="none" />,
    Light: <g><circle cx="20" cy="20" r="6" fill={color} /><g stroke={color} strokeWidth="1.6" strokeLinecap="round"><line x1="20" y1="4" x2="20" y2="9" /><line x1="20" y1="31" x2="20" y2="36" /><line x1="4" y1="20" x2="9" y2="20" /><line x1="31" y1="20" x2="36" y2="20" /><line x1="8" y1="8" x2="11" y2="11" /><line x1="29" y1="29" x2="32" y2="32" /><line x1="32" y1="8" x2="29" y2="11" /><line x1="11" y1="29" x2="8" y2="32" /></g></g>,
    Materiality: <g fill={color}><rect x="6" y="6" width="9" height="9" /><rect x="17" y="6" width="9" height="9" opacity="0.45" /><rect x="28" y="6" width="6" height="9" opacity="0.7" /><rect x="6" y="17" width="6" height="9" opacity="0.6" /><rect x="14" y="17" width="12" height="9" /><rect x="28" y="17" width="6" height="9" opacity="0.3" /><rect x="6" y="28" width="14" height="6" opacity="0.5" /><rect x="22" y="28" width="12" height="6" /></g>,
    Structure: <g stroke={color} strokeWidth="2" fill="none"><line x1="6" y1="34" x2="34" y2="34" /><line x1="10" y1="34" x2="10" y2="10" /><line x1="30" y1="34" x2="30" y2="10" /><line x1="10" y1="10" x2="30" y2="10" /><line x1="10" y1="34" x2="30" y2="10" /><line x1="30" y1="34" x2="10" y2="10" /></g>,
    Context: <g stroke={color} strokeWidth="1.8" fill="none"><circle cx="20" cy="20" r="13" /><circle cx="20" cy="20" r="7" /><circle cx="20" cy="20" r="2" fill={color} /></g>,
    Circulation: <path d="M6 20 Q14 6 20 20 T34 20" stroke={color} strokeWidth="2" fill="none" strokeLinecap="round" />,
    Craft: <g stroke={color} strokeWidth="1.6" fill="none"><path d="M8 12 L32 12 M8 20 L32 20 M8 28 L32 28" /><path d="M14 8 L14 32 M26 8 L26 32" /></g>
  };
  return <svg width="40" height="40" viewBox="0 0 40 40">{m[name]}</svg>;
}

function OldElement({ name, color = C.ink }) {
  const m = {
    Column: <g fill={color}><rect x="14" y="6" width="12" height="3" /><rect x="14" y="31" width="12" height="3" /><rect x="17" y="9" width="6" height="22" /></g>,
    Wall: <rect x="6" y="6" width="28" height="28" fill={color} />,
    Arch: <g fill={color}><rect x="6" y="22" width="6" height="12" /><rect x="28" y="22" width="6" height="12" /><path d="M6 22 Q6 6 20 6 Q34 6 34 22 L28 22 Q28 12 20 12 Q12 12 12 22 Z" /></g>,
    Door: <g fill={color}><rect x="10" y="6" width="20" height="28" /><circle cx="26" cy="20" r="1.5" fill={C.paper} /></g>,
    Window: <g fill={color}><rect x="6" y="8" width="28" height="24" /><g fill={C.paper}><rect x="9" y="11" width="9" height="9" /><rect x="22" y="11" width="9" height="9" /><rect x="9" y="22" width="9" height="7" /><rect x="22" y="22" width="9" height="7" /></g></g>,
    Stair: <g fill={color}><rect x="6" y="28" width="28" height="6" /><rect x="10" y="22" width="24" height="6" /><rect x="14" y="16" width="20" height="6" /><rect x="18" y="10" width="16" height="6" /></g>,
    Ramp: <g fill={color}><polygon points="6,34 34,34 34,6" /></g>,
    Roof: <g fill={color}><polygon points="4,22 20,6 36,22 36,26 4,26" /></g>,
    Ceiling: <g fill={color}><rect x="4" y="6" width="32" height="6" /><g stroke={color} strokeWidth="1.4"><line x1="8" y1="14" x2="8" y2="34" /><line x1="14" y1="14" x2="14" y2="34" /><line x1="20" y1="14" x2="20" y2="34" /><line x1="26" y1="14" x2="26" y2="34" /><line x1="32" y1="14" x2="32" y2="34" /></g></g>,
    Floor: <g fill={color}><rect x="4" y="28" width="32" height="6" /><g stroke={color} strokeWidth="1.2"><line x1="4" y1="22" x2="36" y2="22" /><line x1="4" y1="16" x2="36" y2="16" /><line x1="4" y1="10" x2="36" y2="10" /></g></g>,
    Facade: <g fill={color}><rect x="6" y="6" width="28" height="28" /><g fill={C.paper}><rect x="9" y="9" width="3" height="6" /><rect x="14" y="9" width="3" height="6" /><rect x="19" y="9" width="3" height="6" /><rect x="24" y="9" width="3" height="6" /><rect x="29" y="9" width="2" height="6" /><rect x="9" y="18" width="3" height="6" /><rect x="14" y="18" width="3" height="6" /><rect x="19" y="18" width="3" height="6" /><rect x="24" y="18" width="3" height="6" /><rect x="29" y="18" width="2" height="6" /><rect x="9" y="27" width="3" height="5" /><rect x="14" y="27" width="3" height="5" /><rect x="19" y="27" width="3" height="5" /><rect x="24" y="27" width="3" height="5" /></g></g>,
    Railing: <g fill={color}><rect x="4" y="14" width="32" height="3" /><rect x="6" y="17" width="3" height="14" /><rect x="14" y="17" width="3" height="14" /><rect x="22" y="17" width="3" height="14" /><rect x="30" y="17" width="3" height="14" /><rect x="4" y="31" width="32" height="3" /></g>,
    Joint: <g fill={color}><rect x="6" y="6" width="13" height="13" /><rect x="21" y="6" width="13" height="13" /><rect x="6" y="21" width="13" height="13" /><rect x="21" y="21" width="13" height="13" /></g>,
    Pavement: <g fill={color}><rect x="4" y="4" width="14" height="14" /><rect x="20" y="4" width="16" height="14" /><rect x="4" y="20" width="16" height="16" /><rect x="22" y="20" width="14" height="16" /></g>
  };
  return <svg width="40" height="40" viewBox="0 0 40 40">{m[name]}</svg>;
}

// ---------------------------------------------------------------------
// Comparison cell — old vs new, with label
// ---------------------------------------------------------------------
function CompareCell({ name, OldGlyph, newGlyphFn }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '88px 88px',
      gap: 0, alignItems: 'stretch',
      borderTop: `1px solid rgba(15,15,14,0.08)`
    }}>
      <div style={{
        height: 88, display: 'flex', alignItems: 'center', justifyContent: 'center',
        borderRight: `1px solid rgba(15,15,14,0.08)`,
        background: 'rgba(15,15,14,0.02)'
      }}>
        <OldGlyph name={name} color={C.ink} />
      </div>
      <div style={{
        height: 88, display: 'flex', alignItems: 'center', justifyContent: 'center'
      }}>
        {newGlyphFn(name, C.ink)}
      </div>
      <div style={{
        gridColumn: '1 / 3', padding: '6px 10px',
        borderTop: `1px solid rgba(15,15,14,0.05)`,
        fontFamily: MONO, fontSize: 10, color: C.inkMuted,
        letterSpacing: '0.04em', textTransform: 'uppercase',
        textAlign: 'center'
      }}>{name}</div>
    </div>
  );
}

function CompareGrid({ items, OldGlyph, newGlyphFn, cols = 4 }) {
  return (
    <div style={{
      padding: 18, background: C.paper, fontFamily: FONT, color: C.ink,
      height: '100%', overflow: 'auto'
    }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: '70px 70px',
        gap: 14, marginBottom: 14, paddingBottom: 12,
        borderBottom: `1px solid rgba(15,15,14,0.15)`,
        fontFamily: MONO, fontSize: 10,
        color: C.inkMuted, letterSpacing: '0.06em', textTransform: 'uppercase'
      }}>
        <span style={{ textAlign: 'center', paddingLeft: 8 }}>v1 — current</span>
        <span style={{ textAlign: 'center', paddingLeft: 8 }}>v2 — refined</span>
      </div>
      <div style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${cols}, 176px)`,
        gap: 16
      }}>
        {items.map(name =>
          <CompareCell key={name} name={name} OldGlyph={OldGlyph} newGlyphFn={newGlyphFn} />
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------
// Solo grid — just the new ones, large
// ---------------------------------------------------------------------
function SoloGrid({ items, newGlyphFn, cols = 4 }) {
  return (
    <div style={{
      padding: 22, background: C.paper, fontFamily: FONT, color: C.ink,
      height: '100%', overflow: 'auto'
    }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${cols}, 1fr)`,
        gap: 14
      }}>
        {items.map(name =>
          <div key={name} style={{
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 8,
            padding: '14px 6px',
            border: `1px solid rgba(15,15,14,0.10)`,
            borderRadius: 8
          }}>
            {newGlyphFn(name, C.ink)}
            <div style={{
              fontFamily: MONO, fontSize: 10, color: C.inkMuted,
              letterSpacing: '0.05em', textTransform: 'uppercase'
            }}>{name}</div>
          </div>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------
// Tagger using v2 glyphs — Building (typology + concept)
// ---------------------------------------------------------------------
function TaggerBuildingV2({ photo = PHOTO_BUILDING, mode = 'reference', picked = { typology: 'Cultural', concepts: ['Light','Materiality'] } }) {
  return (
    <PaperShell photo={photo} mode={mode} saveLabel="Save · 3 tags">
      <SwatchSection label="Typology" summary={picked.typology} layout="grid" cols={4}>
        {TYPOLOGY.slice(0,8).map(t =>
          <SwatchTile key={t} active={picked.typology === t} mode={mode} label={t} size={70}>
            {typologyGlyphV2(t, picked.typology === t ? C.paper : C.ink)}
          </SwatchTile>
        )}
      </SwatchSection>

      <SwatchSection label="Concept" summary={(picked.concepts || []).join(' · ')} layout="grid" cols={4}>
        {CONCEPTS.map(c =>
          <SwatchTile key={c} active={(picked.concepts || []).includes(c)} mode={mode} label={c} size={70}>
            {conceptGlyphV2(c, (picked.concepts || []).includes(c) ? C.paper : C.ink)}
          </SwatchTile>
        )}
      </SwatchSection>

      <div style={{ padding: '18px 16px 8px' }}>
        <div style={{ fontSize: 12, color: C.inkMuted, fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 10 }}>Author · Year</div>
        <input style={{
          width: '100%', boxSizing: 'border-box',
          background: 'transparent', color: C.ink,
          border: '0', borderBottom: `1px solid rgba(15,15,14,0.25)`,
          padding: '8px 0', fontSize: 15, fontFamily: FONT,
          letterSpacing: '-0.005em', outline: 'none'
        }} placeholder="e.g. Kahn · 1972" />
      </div>
    </PaperShell>
  );
}

// ---------------------------------------------------------------------
// Tagger using v2 glyphs — Element (element + materiality + concept)
// ---------------------------------------------------------------------
function TaggerElementV2({ photo = PHOTO_DETAIL, mode = 'reference', picked = { element: 'Column', materials: ['Stone'], concepts: ['Materiality','Craft'] } }) {
  return (
    <PaperShell photo={photo} mode={mode} saveLabel="Save · 4 tags">
      <SwatchSection label="Element" summary={picked.element} layout="grid" cols={4}>
        {ELEMENTS.slice(0,8).map(e =>
          <SwatchTile key={e} active={picked.element === e} mode={mode} label={e} size={70}>
            {elementGlyphV2(e, picked.element === e ? C.paper : C.ink)}
          </SwatchTile>
        )}
      </SwatchSection>

      <SwatchSection label="Materiality" summary={(picked.materials || []).join(' · ')} layout="grid" cols={4}>
        {MATERIALS.slice(0,8).map(m => {
          const isActive = (picked.materials || []).includes(m);
          return (
            <div key={m} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{
                width: 70, height: 70, borderRadius: 10,
                border: `1px solid ${isActive ? C.ink : 'rgba(15,15,14,0.16)'}`,
                position: 'relative', overflow: 'hidden',
                background: isActive ? C.ink : C.paper
              }}>
                <svg width="70" height="70" viewBox="0 0 70 70" style={{ position: 'absolute', inset: 0 }}>
                  <defs>{materialPattern(m, isActive ? C.paper : C.ink)}</defs>
                  <rect width="70" height="70" fill={`url(#mat-${m.toLowerCase()})`} opacity={isActive ? 0.9 : 1} />
                </svg>
                {isActive &&
                  <div style={{
                    position: 'absolute', top: 5, right: 5,
                    width: 14, height: 14, borderRadius: 99,
                    background: mode === 'reference' ? C.mint : C.yellow,
                    color: C.ink, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                    zIndex: 2
                  }}>{I.check(9)}</div>
                }
              </div>
              <div style={{
                fontSize: 11, fontWeight: 500, color: isActive ? C.ink : C.inkMuted,
                letterSpacing: '-0.005em', textAlign: 'center'
              }}>{m}</div>
            </div>
          );
        })}
      </SwatchSection>

      <SwatchSection label="Concept" summary={(picked.concepts || []).join(' · ')} layout="grid" cols={4}>
        {CONCEPTS.map(c =>
          <SwatchTile key={c} active={(picked.concepts || []).includes(c)} mode={mode} label={c} size={70}>
            {conceptGlyphV2(c, (picked.concepts || []).includes(c) ? C.paper : C.ink)}
          </SwatchTile>
        )}
      </SwatchSection>
    </PaperShell>
  );
}

Object.assign(window, {
  CompareGrid, SoloGrid, OldTypology, OldConcept, OldElement,
  TaggerBuildingV2, TaggerElementV2,
  TYPOLOGY_LIST, CONCEPT_LIST, ELEMENT_LIST
});
