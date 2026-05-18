// PAK-PULSE · shared atoms
// PulseDot, AgentDots, Counter, Sparkline, Skeleton, StatusBar, TabBar,
// MapTwinCity (stylized Islamabad/Rawalpindi vector)

const { useEffect, useState, useRef, useMemo } = React;

// ── pp Status Bar (dark, baked into screen) ───────────────
function PPStatusBar({ time = '14:32' }) {
  return (
    <div className="pp-statusbar">
      <span className="pp-mono">{time}</span>
      <div className="ind">
        {/* signal */}
        <svg width="17" height="11" viewBox="0 0 17 11"><g fill="#F5F7FA">
          <rect x="0"  y="7" width="3" height="4" rx="0.6"/>
          <rect x="4.5" y="5" width="3" height="6" rx="0.6"/>
          <rect x="9"  y="3" width="3" height="8" rx="0.6"/>
          <rect x="13.5" y="0" width="3" height="11" rx="0.6"/>
        </g></svg>
        {/* lte */}
        <span className="pp-mono" style={{fontSize: 10, fontWeight: 700, color: '#F5F7FA', margin: '0 2px'}}>LTE</span>
        {/* battery */}
        <svg width="26" height="12" viewBox="0 0 26 12">
          <rect x="0.5" y="0.5" width="22" height="11" rx="3" stroke="#F5F7FA" strokeOpacity=".5" fill="none"/>
          <rect x="2"   y="2"   width="19" height="8"  rx="1.6" fill="#3DDC97"/>
          <path d="M24 4v4c.8-.3 1.5-1.3 1.5-2s-.7-1.7-1.5-2z" fill="#F5F7FA" fillOpacity=".5"/>
        </svg>
      </div>
    </div>
  );
}

// ── PulseDot · single severity-colored pin ────────────────
function PulseDot({ color, speed = '1.6s', size = 12 }) {
  return (
    <span className="pulse-pin" style={{ '--c': color, '--d': speed, width: size * 1.5, height: size * 1.5 }}>
      <i className="core" style={{ width: size, height: size }} />
    </span>
  );
}

// ── AgentDots · thinking indicator ────────────────────────
function AgentDots({ color = '#94A3B8' }) {
  return (
    <span className="thinking" style={{ '--c': color }}>
      <i/><i/><i/>
    </span>
  );
}

// ── Counter · rolls a number up ──────────────────────────
function Counter({ to, dur = 1400, suffix = '', decimals = 0, className = '' }) {
  const [n, setN] = useState(0);
  useEffect(() => {
    let raf, t0;
    const ease = (x) => 1 - Math.pow(1 - x, 3);
    const tick = (t) => {
      if (!t0) t0 = t;
      const p = Math.min(1, (t - t0) / dur);
      setN(to * ease(p));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [to, dur]);
  const f = decimals > 0
    ? n.toFixed(decimals)
    : Math.round(n).toLocaleString('en-US');
  return <span className={'pp-mono ' + className}>{f}{suffix}</span>;
}

// ── live "time ago" string that updates each second ───────
function TimeAgo({ seconds: s0 }) {
  const [s, setS] = useState(s0);
  useEffect(() => { const id = setInterval(() => setS((v) => v + 1), 1000); return () => clearInterval(id); }, []);
  const fmt = s < 60
    ? `${s}s ago`
    : s < 3600 ? `${Math.floor(s / 60)}m ${s % 60}s ago`
    : `${Math.floor(s / 3600)}h ${Math.floor(s % 3600 / 60)}m ago`;
  return <span className="pp-mono">{fmt}</span>;
}

// ── Sparkline · low-poly area chart ───────────────────────
function Sparkline({ data, color = '#FF3B5C', w = 80, h = 24, fill = true }) {
  const max = Math.max(...data), min = Math.min(...data);
  const range = max - min || 1;
  const pts = data.map((v, i) => `${(i / (data.length - 1)) * w},${h - ((v - min) / range) * h * 0.9 - 1}`);
  const id = useMemo(() => 'sp' + Math.random().toString(36).slice(2, 7), []);
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ display: 'block' }}>
      {fill && (
        <>
          <defs>
            <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={color} stopOpacity="0.5"/>
              <stop offset="100%" stopColor={color} stopOpacity="0"/>
            </linearGradient>
          </defs>
          <path d={`M0,${h} L${pts.join(' L')} L${w},${h} Z`} fill={`url(#${id})`} />
        </>
      )}
      <polyline points={pts.join(' ')} fill="none" stroke={color} strokeWidth="1.4"
        strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ── Skeleton row ─────────────────────────────────────────
function Skel({ w = '100%', h = 12, r = 6, style = {} }) {
  return <div className="skel" style={{ width: w, height: h, borderRadius: r, ...style }} />;
}

// ── MapTwinCity · stylized Islamabad+Rawalpindi vector ────
// Top: Margalla Hills. Middle: sectors of Islamabad (F-, G-, H-, I-).
// Lower-right: Rawalpindi cantt grid + Saddar. Soan river curves SE.
// Roads: GT Road (N-5), Islamabad Expressway, Kashmir Hwy, Murree Rd.
function MapTwinCity({ pins = [], height = 360, showLabels = true, showRoute, showZone, replay = false }) {
  return (
    <div style={{ position: 'relative', width: '100%', height, background: 'radial-gradient(120% 80% at 30% 20%, #0F1524 0%, #070A12 70%)' }}>
      <svg viewBox="0 0 390 360" preserveAspectRatio="xMidYMid slice" width="100%" height="100%" style={{ display: 'block' }}>
        <defs>
          <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
            <path d="M20 0H0V20" fill="none" stroke="rgba(255,255,255,0.025)" strokeWidth="0.5"/>
          </pattern>
          <radialGradient id="floodGlow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#4D9FFF" stopOpacity="0.5"/>
            <stop offset="100%" stopColor="#4D9FFF" stopOpacity="0"/>
          </radialGradient>
          <radialGradient id="heatGlow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#FF6B3D" stopOpacity="0.4"/>
            <stop offset="100%" stopColor="#FF6B3D" stopOpacity="0"/>
          </radialGradient>
          <radialGradient id="critGlow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#FF3B5C" stopOpacity="0.55"/>
            <stop offset="100%" stopColor="#FF3B5C" stopOpacity="0"/>
          </radialGradient>
        </defs>

        {/* grid */}
        <rect width="390" height="360" fill="url(#grid)"/>

        {/* Margalla Hills (top) — natural strokes */}
        <path d="M-10 60 C 40 30, 90 50, 140 35 S 250 55, 300 30 S 400 50, 410 35"
              fill="none" stroke="#2A3142" strokeWidth="0.7" />
        <path d="M-10 75 C 50 55, 110 70, 160 55 S 260 75, 320 50 S 400 70, 410 55"
              fill="none" stroke="#2A3142" strokeWidth="0.7" strokeDasharray="2 3" />
        <path d="M-10 88 C 60 70, 100 88, 180 72 S 280 92, 340 70 S 400 85, 410 75"
              fill="none" stroke="#1F2433" strokeWidth="0.7" />
        {showLabels && <text x="60" y="48" fill="#475467" fontSize="7" fontFamily="JetBrains Mono">MARGALLA HILLS · 1604m</text>}

        {/* Soan river — curve */}
        <path d="M40 280 C 110 250, 180 290, 240 270 S 360 320, 410 300"
              fill="none" stroke="#1E3050" strokeWidth="3" strokeLinecap="round" opacity="0.9"/>
        <path d="M40 280 C 110 250, 180 290, 240 270 S 360 320, 410 300"
              fill="none" stroke="#2D4A78" strokeWidth="1.4" strokeLinecap="round" opacity="0.7"/>
        {showLabels && <text x="160" y="285" fill="#3A5780" fontSize="7" fontFamily="JetBrains Mono" fontStyle="italic">soan river</text>}

        {/* Major roads · Islamabad Expressway (N-S) */}
        <path d="M250 90 L 270 200 L 310 290 L 340 360" stroke="#293345" strokeWidth="6" fill="none" strokeLinecap="round"/>
        <path d="M250 90 L 270 200 L 310 290 L 340 360" stroke="#3A4358" strokeWidth="1" fill="none" strokeDasharray="3 3"/>
        {/* GT Road / N-5 — east axis */}
        <path d="M210 200 L 320 230 L 410 260" stroke="#293345" strokeWidth="7" fill="none" strokeLinecap="round"/>
        <path d="M210 200 L 320 230 L 410 260" stroke="#4A5670" strokeWidth="1" fill="none" strokeDasharray="3 3"/>
        {showLabels && <text x="225" y="195" fill="#64748B" fontSize="8" fontFamily="JetBrains Mono" fontWeight="600">N-5  GT ROAD</text>}
        {/* Kashmir Highway (E-W islamabad) */}
        <path d="M30 130 L 260 150" stroke="#252D3D" strokeWidth="5" fill="none" strokeLinecap="round"/>
        {showLabels && <text x="35" y="125" fill="#475467" fontSize="7" fontFamily="JetBrains Mono">KASHMIR HWY</text>}
        {/* 9th Avenue */}
        <path d="M150 80 L 160 290" stroke="#252D3D" strokeWidth="3" fill="none"/>
        {/* Margalla Road */}
        <path d="M40 105 L 250 110" stroke="#252D3D" strokeWidth="3" fill="none"/>
        {/* Murree Rd (Rawalpindi) */}
        <path d="M280 200 L 330 320" stroke="#252D3D" strokeWidth="4" fill="none" strokeLinecap="round"/>
        {showLabels && <text x="288" y="265" fill="#64748B" fontSize="7" fontFamily="JetBrains Mono" transform="rotate(60 288 265)">MURREE RD</text>}

        {/* Islamabad sector grid — sectors as soft rects */}
        {[
          ['F-7', 90,  130], ['F-8', 60, 130], ['F-10', 35, 145],
          ['G-7', 90,  155], ['G-8', 60, 155], ['G-9',  60, 175],
          ['G-10',35,  180], ['G-11',20, 195],
          ['I-8', 90,  185], ['I-9',  90, 210], ['I-10',125, 200],
          ['H-8', 130, 165], ['H-9', 155, 175],
        ].map(([name, x, y]) => (
          <g key={name}>
            <rect x={x - 11} y={y - 7} width="22" height="14" rx="1.5" fill="rgba(255,255,255,0.018)" stroke="rgba(255,255,255,0.06)" strokeWidth="0.4"/>
            {showLabels && <text x={x} y={y + 2.2} fill="#64748B" fontSize="6.4" fontFamily="JetBrains Mono" textAnchor="middle" fontWeight="600">{name}</text>}
          </g>
        ))}

        {/* Rawalpindi cantt — denser, irregular */}
        {[
          ['SADDAR', 295, 245],
          ['RAJA BZR', 280, 270],
          ['CANTT',   320, 260],
          ['PESHAWAR\nMORE', 240, 235],
          ['CHAKLALA', 340, 285],
        ].map(([name, x, y]) => (
          <g key={name}>
            <rect x={x - 16} y={y - 8} width="32" height="16" rx="1.5"
              fill="rgba(255,255,255,0.025)" stroke="rgba(255,255,255,0.08)" strokeWidth="0.4"/>
            {showLabels && name.split('\n').map((ln, i) => (
              <text key={i} x={x} y={y - 1 + i*6} fill="#64748B" fontSize="5.8" fontFamily="JetBrains Mono" textAnchor="middle" fontWeight="600">{ln}</text>
            ))}
          </g>
        ))}

        {/* labels */}
        {showLabels && <>
          <text x="60" y="280" fill="#5A6B82" fontSize="11" fontWeight="800" letterSpacing="3" fontFamily="Plus Jakarta Sans">ISLAMABAD</text>
          <text x="295" y="220" fill="#5A6B82" fontSize="9" fontWeight="800" letterSpacing="2" fontFamily="Plus Jakarta Sans">RAWALPINDI</text>
        </>}

        {/* affected zone (e.g. flood polygon) */}
        {showZone && (
          <>
            <path d={showZone.d} fill={showZone.color + '22'} stroke={showZone.color} strokeWidth="1" strokeDasharray="3 2"/>
          </>
        )}

        {/* reroute polylines */}
        {showRoute && (
          <>
            {/* original (faded) */}
            <path d={showRoute.from} fill="none" stroke="#FF3B5C" strokeWidth="2.2" strokeLinecap="round" opacity="0.25" strokeDasharray="3 4"/>
            {/* new — draws itself */}
            <path d={showRoute.to} fill="none" stroke="#3DDC97" strokeWidth="2.6" strokeLinecap="round"
              className="draw" style={{ '--len': 300 }} />
            <path d={showRoute.to} fill="none" stroke="#3DDC97" strokeWidth="2.6" strokeLinecap="round"
              className="draw-loop" opacity="0.7"/>
          </>
        )}

        {/* pin glows */}
        {pins.map((p, i) => p.glow && (
          <circle key={'g'+i} cx={p.x} cy={p.y} r="36"
            fill={`url(#${p.type === 'flood' ? 'floodGlow' : p.type === 'heat' ? 'heatGlow' : 'critGlow'})`} />
        ))}

        {/* compass mark · top-right */}
        <g transform="translate(360 28)">
          <circle r="11" fill="none" stroke="rgba(148,163,184,0.25)" strokeWidth="0.5"/>
          <path d="M0 -8 L 3 0 L 0 4 L -3 0 Z" fill="#94A3B8"/>
          <text y="-13" fontSize="6" fill="#94A3B8" textAnchor="middle" fontFamily="JetBrains Mono" fontWeight="700">N</text>
        </g>
      </svg>

      {/* scanlines and sweep for radar feel */}
      <div className="scanline"/>
      {replay && <div className="sweep"/>}

      {/* HTML pins (so they pulse cleanly via CSS) */}
      {pins.map((p, i) => (
        <div key={i} style={{
          position: 'absolute',
          left: `${(p.x / 390) * 100}%`,
          top:  `${(p.y / 360) * 100}%`,
          transform: 'translate(-50%, -50%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          zIndex: 5,
        }}>
          <PulseDot color={p.color} speed={p.speed || '1.6s'} size={p.size || 12} />
          {p.label && (
            <span className="pp-mono" style={{
              fontSize: 8.5, fontWeight: 700, padding: '2px 5px',
              background: 'rgba(10,14,26,0.85)', backdropFilter: 'blur(8px)',
              color: p.color, border: `1px solid ${p.color}55`,
              borderRadius: 3, letterSpacing: '0.05em', textTransform: 'uppercase',
              whiteSpace: 'nowrap', boxShadow: `0 0 12px ${p.color}33`,
            }}>{p.label}</span>
          )}
        </div>
      ))}
    </div>
  );
}

// ── Home indicator + Tab bar ─────────────────────────────
function HomeBar() { return <div className="home-bar"><i/></div>; }

function TabBar({ active = 'live' }) {
  const tabs = [
    ['live',     'LIVE',     <path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.93 4.93l2.12 2.12M16.95 16.95l2.12 2.12M4.93 19.07l2.12-2.12M16.95 7.05l2.12-2.12" strokeWidth="1.6" fill="none"/>],
    ['signals', 'SIGNALS',  <><circle cx="12" cy="12" r="2" fill="currentColor"/><path d="M5 12a7 7 0 0 1 14 0M3 12a9 9 0 0 1 18 0" strokeWidth="1.6" fill="none"/></>],
    ['trace',   'TRACE',    <><circle cx="6"  cy="6" r="2" strokeWidth="1.6" fill="none"/><circle cx="18" cy="6" r="2" strokeWidth="1.6" fill="none"/><circle cx="12" cy="18" r="2" strokeWidth="1.6" fill="none"/><path d="M7.5 7.5l3 9M16.5 7.5l-3 9" strokeWidth="1.4"/></>],
    ['history', 'HISTORY',  <><circle cx="12" cy="12" r="9" strokeWidth="1.6" fill="none"/><path d="M12 7v5l3 2" strokeWidth="1.6" fill="none" strokeLinecap="round"/></>],
    ['me',      'ME',       <><circle cx="12" cy="8" r="3.2" strokeWidth="1.6" fill="none"/><path d="M5 20c.7-3.6 3.5-5 7-5s6.3 1.4 7 5" strokeWidth="1.6" fill="none" strokeLinecap="round"/></>],
  ];
  return (
    <div className="tab-bar">
      {tabs.map(([id, label, icon]) => (
        <button key={id} className={active === id ? 'active' : ''}>
          <svg width="22" height="22" viewBox="0 0 24 24" stroke="currentColor" fill="none">{icon}</svg>
          <span>{label}</span>
        </button>
      ))}
      <HomeBar/>
    </div>
  );
}

// Brand wordmark — simple, mono, with a pulse dot
function Wordmark({ size = 18, color }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, fontFamily: 'Plus Jakarta Sans', fontWeight: 800, fontSize: size, letterSpacing: '-0.02em', color: color || 'var(--text-1)' }}>
      <span style={{ position: 'relative', display: 'inline-block', width: size * 0.7, height: size * 0.7 }}>
        <span style={{ position: 'absolute', inset: 0, border: '1.5px solid currentColor', borderRadius: '50%' }}/>
        <span style={{ position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%,-50%)', width: size * 0.3, height: size * 0.3, background: 'var(--sev-critical)', borderRadius: '50%', boxShadow: '0 0 8px var(--sev-critical)' }}/>
      </span>
      <span>PAK<span style={{ opacity: .4 }}>·</span>PULSE</span>
    </span>
  );
}

Object.assign(window, {
  PPStatusBar, PulseDot, AgentDots, Counter, TimeAgo, Sparkline, Skel,
  MapTwinCity, HomeBar, TabBar, Wordmark,
});
