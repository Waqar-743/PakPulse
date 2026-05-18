// PAK-PULSE · screens A — Onboarding, Live Map, Crisis Detail, Reasoning Trace

const { useState: useStateA, useEffect: useEffectA } = React;

// ════════════════════════════════════════════════════════════
// 1 · ONBOARDING — splash + 3 cards
// ════════════════════════════════════════════════════════════
function ScreenOnboarding({ step = 1 }) {
  const slides = [
    {
      eyebrow: 'PROTOCOL ONLINE',
      title: 'Crisis intelligence,\nin real time.',
      body: 'Pak-Pulse listens to thousands of signals across Pakistan and surfaces what matters in the next ten minutes.',
      art: (
        <div style={{ position: 'relative', width: 220, height: 220 }}>
          <div style={{ position:'absolute', inset:0, borderRadius:'50%', border:'1px solid #2A3142' }}/>
          <div style={{ position:'absolute', inset:24, borderRadius:'50%', border:'1px dashed #2A3142' }}/>
          <div style={{ position:'absolute', inset:60, borderRadius:'50%', border:'1px solid #2A3142' }}/>
          <div style={{ position:'absolute', left:'50%', top:'50%', transform:'translate(-50%,-50%)' }}>
            <PulseDot color="#FF3B5C" size={28} speed="1.4s"/>
          </div>
          {/* satellite ticks */}
          <div style={{ position:'absolute', left:'85%', top:'30%' }}><PulseDot color="#4D9FFF" size={8} speed="2s"/></div>
          <div style={{ position:'absolute', left:'15%', top:'60%' }}><PulseDot color="#FFD23D" size={8} speed="2.4s"/></div>
          <div style={{ position:'absolute', left:'70%', top:'80%' }}><PulseDot color="#B84DFF" size={8} speed="2.8s"/></div>
        </div>
      ),
    },
    {
      eyebrow: '04 AGENTS · LIVE',
      title: 'Four agents,\none decision.',
      body: 'Watcher · Analyst · Coordinator · Responder. Every recommendation traces back to the signal that triggered it.',
      art: (
        <div style={{ display:'flex', flexDirection:'column', gap:14, width:'85%' }}>
          {[
            ['WATCHER', '#4D9FFF', 'Listening · 4,812 signals'],
            ['ANALYST', '#B84DFF', 'Scoring RSI · 87.4'],
            ['COORDINATOR', '#FFD23D', 'Routing · N-5 reroute'],
            ['RESPONDER', '#3DDC97', 'Standing by'],
          ].map(([n, c, s], i) => (
            <div key={n} className="card" style={{ padding:'10px 12px', display:'flex', alignItems:'center', gap:10, animation:`pp-signal-in .5s ${i*0.12}s both` }}>
              <div style={{ width:8, height:8, borderRadius:'50%', background:c, boxShadow:`0 0 10px ${c}` }}/>
              <span className="pp-mono" style={{ fontSize:11, fontWeight:700, letterSpacing:'0.08em' }}>{n}</span>
              <span style={{ flex:1 }}/>
              <AgentDots color={c}/>
              <span style={{ fontSize:10, color:'var(--text-3)' }}>{s}</span>
            </div>
          ))}
        </div>
      ),
    },
    {
      eyebrow: 'BUILT FOR PAKISTAN',
      title: 'اردو, English\nand Roman Urdu.',
      body: 'Signals arrive in the language they were sent. We render them faithfully — Nastaliq for Urdu, native scripts for everything else.',
      art: (
        <div className="card" style={{ width:'85%', padding:18 }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10 }}>
            <span className="chip" style={{ '--c':'#4D9FFF' }}><span className="dot"/>TWITTER · @rwp_traffic</span>
            <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>2m ago</span>
          </div>
          <p className="pp-urdu" style={{ margin:0, color:'var(--text-1)', fontSize:18, lineHeight:1.9 }}>
            صدر روڈ پر شدید پانی جمع، ٹریفک بند۔
          </p>
          <p style={{ margin:'8px 0 0', color:'var(--text-2)', fontSize:13, fontStyle:'italic' }}>
            "Heavy flooding on Saddar Road, traffic halted."
          </p>
        </div>
      ),
    },
  ];
  const s = slides[step - 1];
  return (
    <div className="pp-screen">
      <PPStatusBar/>
      <div style={{ padding:'12px 24px 0', display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <Wordmark size={15}/>
        <button style={{ background:'none', border:'none', color:'var(--text-3)', fontSize:13, fontWeight:600, letterSpacing:'0.04em' }}>SKIP</button>
      </div>

      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:30, padding:'40px 28px 0', height:'calc(100% - 200px)' }}>
        {s.art}
        <div style={{ textAlign:'center' }}>
          <div className="pp-mono" style={{ fontSize:10, fontWeight:700, letterSpacing:'0.16em', color:'var(--sev-critical)', marginBottom:14, textTransform:'uppercase' }}>{s.eyebrow}</div>
          <h2 style={{ margin:0, fontSize:28, fontWeight:800, lineHeight:1.15, letterSpacing:'-0.03em', whiteSpace:'pre-line' }}>{s.title}</h2>
          <p style={{ margin:'14px 0 0', color:'var(--text-2)', fontSize:14, lineHeight:1.5 }}>{s.body}</p>
        </div>
      </div>

      <div style={{ position:'absolute', bottom:60, left:0, right:0, padding:'0 28px' }}>
        <div style={{ display:'flex', gap:6, justifyContent:'center', marginBottom:22 }}>
          {slides.map((_, i) => (
            <span key={i} style={{ width:i===step-1?22:6, height:6, borderRadius:3, background:i===step-1?'var(--sev-critical)':'var(--border)', transition:'width .3s' }}/>
          ))}
        </div>
        <button className="btn btn-primary" style={{ width:'100%', '--c':'var(--sev-critical)' }}>
          {step < 3 ? 'CONTINUE' : 'ENTER CONSOLE'}
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 7h8M7 3l4 4-4 4"/></svg>
        </button>
      </div>
      <HomeBar/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 2 · LIVE CRISIS MAP — the hero
// ════════════════════════════════════════════════════════════
function ScreenLiveMap() {
  const [filter, setFilter] = useStateA('all');
  const allPins = [
    { x: 290, y: 250, color: '#FF3B5C', type: 'flood', glow: true,  speed: '1.2s', size: 14, label: 'FLD-014' },
    { x: 195, y: 195, color: '#FF8A3D', type: 'heat',  speed: '1.8s', size: 12, label: 'HT-007' },
    { x: 105, y: 158, color: '#B84DFF', type: 'protest', glow: true, speed: '1.6s', size: 12, label: 'PR-022' },
    { x: 65,  y: 130, color: '#3DDC97', speed: '2.4s',  size: 10 },
    { x: 320, y: 230, color: '#FFD23D', speed: '2.0s',  size: 10 },
    { x: 250, y: 95,  color: '#4D9FFF', speed: '2.4s',  size: 10 },
  ];
  return (
    <div className="pp-screen">
      <PPStatusBar/>

      {/* search + filters overlay */}
      <div style={{ position:'absolute', left:0, right:0, top:54, zIndex:30, padding:'4px 16px 12px', background:'linear-gradient(180deg, rgba(10,14,26,0.95) 60%, transparent)' }}>
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
          <Wordmark size={14}/>
          <span style={{ flex:1 }}/>
          <span className="chip" style={{ '--c':'#3DDC97' }}><span className="dot"/>LIVE</span>
          <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="#94A3B8" strokeWidth="1.6"><circle cx="7" cy="7" r="5"/><path d="M11 11l3.5 3.5" strokeLinecap="round"/></svg>
          </button>
        </div>
        <div style={{ display:'flex', gap:6, overflow:'hidden' }}>
          {[
            ['all', 'ALL', '#F5F7FA', 7],
            ['flood', 'FLOOD', '#4D9FFF', 3],
            ['heat', 'HEAT', '#FF6B3D', 2],
            ['protest', 'PROTEST', '#B84DFF', 1],
            ['fire', 'FIRE', '#FF3B5C', 1],
          ].map(([id, label, c, n]) => (
            <button key={id} onClick={() => setFilter(id)} style={{
              padding:'6px 10px', borderRadius:8,
              background: filter===id ? 'var(--bg-card-hi)' : 'transparent',
              border: `1px solid ${filter===id ? c+'66' : 'var(--border)'}`,
              color: filter===id ? c : 'var(--text-2)',
              fontFamily:'JetBrains Mono', fontSize:10, fontWeight:700,
              letterSpacing:'0.06em', display:'flex', alignItems:'center', gap:5,
              boxShadow: filter===id ? `0 0 14px -4px ${c}` : 'none',
            }}>
              {label} <span style={{opacity:.5, fontWeight:500}}>{n}</span>
            </button>
          ))}
        </div>
      </div>

      {/* full-bleed map */}
      <div style={{ position:'absolute', inset:0, paddingTop: 48 }}>
        <MapTwinCity pins={allPins} height={520}/>
      </div>

      {/* live counter top-right */}
      <div style={{ position:'absolute', top:170, right:16, zIndex:25, background:'rgba(10,14,26,0.7)', backdropFilter:'blur(12px)', border:'1px solid var(--border)', borderRadius:10, padding:'8px 10px', textAlign:'right' }}>
        <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.08em' }}>SIGNALS / HR</div>
        <div className="pp-mono" style={{ fontSize:20, fontWeight:700, color:'#3DDC97', textShadow:'0 0 8px rgba(61,220,151,0.6)' }}>
          <Counter to={2847}/>
        </div>
      </div>

      {/* bottom sheet — partial */}
      <div style={{
        position:'absolute', left:0, right:0, bottom:0, zIndex:30,
        background:'rgba(10,14,26,0.92)',
        backdropFilter:'blur(20px) saturate(1.4)',
        WebkitBackdropFilter:'blur(20px) saturate(1.4)',
        borderTop:'1px solid var(--border)',
        borderRadius:'20px 20px 0 0',
        padding:'8px 0 100px',
        maxHeight:'56%',
      }}>
        {/* grabber */}
        <div style={{ width:38, height:4, background:'var(--border-hi)', borderRadius:2, margin:'4px auto 14px' }}/>

        <div style={{ padding:'0 18px', display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom:8 }}>
          <div>
            <div style={{ fontSize:17, fontWeight:800, letterSpacing:'-0.02em' }}>Active Crises</div>
            <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', marginTop:2, letterSpacing:'0.06em' }}>ISLAMABAD · RAWALPINDI · 17:21 PKT</div>
          </div>
          <div style={{ textAlign:'right' }}>
            <div className="pp-mono" style={{ fontSize:24, fontWeight:800 }}><Counter to={7}/></div>
            <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.06em' }}>+2 IN 15M</div>
          </div>
        </div>

        {/* triage row */}
        <div style={{ display:'flex', gap:8, padding:'4px 18px 14px' }}>
          {[
            ['CRITICAL', 3, '#FF3B5C'],
            ['HIGH', 2, '#FF8A3D'],
            ['MOD',  2, '#FFD23D'],
          ].map(([lvl, n, c]) => (
            <div key={lvl} className="card" style={{ flex:1, padding:'8px 10px', borderColor:`${c}40` }}>
              <div className="pp-mono" style={{ fontSize:9, color:c, letterSpacing:'0.08em', fontWeight:700 }}>{lvl}</div>
              <div className="pp-mono" style={{ fontSize:22, fontWeight:800, color:'var(--text-1)' }}><Counter to={n}/></div>
            </div>
          ))}
        </div>

        {/* crisis list */}
        <div style={{ padding:'0 16px', display:'flex', flexDirection:'column', gap:8 }}>
          {[
            { code:'FLD-014', name:'Soan Riverbank Flood', area:'Rawalpindi · Kashmir Rd', sev:'#FF3B5C', sevName:'CRITICAL', rsi:87, t:'1h 47m', spark:[3,4,4,5,7,8,9,10], breathe:true },
            { code:'PR-022', name:'Protest March Blockage', area:'Islamabad · D-Chowk', sev:'#B84DFF', sevName:'HIGH', rsi:62, t:'42m', spark:[2,3,3,4,5,6,5,6] },
            { code:'HT-007', name:'Heatwave Spike Zone', area:'Rawalpindi · Saddar', sev:'#FF8A3D', sevName:'HIGH', rsi:54, t:'3h 12m', spark:[5,6,6,5,7,8,8,7] },
          ].map((c) => (
            <div key={c.code} className={'card ' + (c.breathe ? 'breathe' : '')} style={{
              display:'flex', alignItems:'center', gap:12, padding:'12px 14px',
            }}>
              <PulseDot color={c.sev} speed="1.4s" size={10}/>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ display:'flex', alignItems:'baseline', gap:8 }}>
                  <span className="pp-mono" style={{ fontSize:9, color:c.sev, fontWeight:700 }}>{c.code}</span>
                  <span style={{ fontSize:14, fontWeight:700, letterSpacing:'-0.01em', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{c.name}</span>
                </div>
                <div style={{ fontSize:11, color:'var(--text-3)', marginTop:2 }}>
                  {c.area} · <span className="pp-mono">{c.t}</span>
                </div>
              </div>
              <div style={{ textAlign:'right' }}>
                <Sparkline data={c.spark} color={c.sev} w={50} h={20}/>
                <div className="pp-mono" style={{ fontSize:10, color:c.sev, fontWeight:700, marginTop:2 }}>RSI {c.rsi}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="live"/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 3 · CRISIS DETAIL
// ════════════════════════════════════════════════════════════
function ScreenCrisisDetail() {
  return (
    <div className="pp-screen">
      <PPStatusBar/>

      {/* nav */}
      <div style={{ display:'flex', alignItems:'center', gap:8, padding:'4px 16px 12px' }}>
        <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
          <svg width="13" height="13" viewBox="0 0 14 14" fill="none" stroke="#94A3B8" strokeWidth="1.8"><path d="M9 2L3 7l6 5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ flex:1, textAlign:'center' }}>
          <div className="pp-mono" style={{ fontSize:10, fontWeight:700, color:'#FF3B5C', letterSpacing:'0.1em' }}>● ACTIVE</div>
          <div className="pp-mono" style={{ fontSize:11, color:'var(--text-3)', letterSpacing:'0.06em', marginTop:1 }}>FLD-014</div>
        </div>
        <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="#94A3B8"><circle cx="3" cy="7" r="1.2"/><circle cx="7" cy="7" r="1.2"/><circle cx="11" cy="7" r="1.2"/></svg>
        </button>
      </div>

      <div className="pp-scroll" style={{ height:'calc(100% - 100px)', paddingBottom:60 }}>
        <div style={{ padding:'0 18px' }}>
          {/* title */}
          <h1 style={{ margin:0, fontSize:24, fontWeight:800, lineHeight:1.15, letterSpacing:'-0.02em' }}>
            Soan Riverbank<br/>Flood Surge
          </h1>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:6 }}>
            <span style={{ fontSize:13, color:'var(--text-2)' }}>Rawalpindi · Kashmir Road</span>
          </div>

          {/* severity strip */}
          <div className="breathe" style={{
            marginTop:14, padding:'12px 14px', borderRadius:12,
            background:'linear-gradient(90deg, rgba(255,59,92,0.18), rgba(255,59,92,0.02))',
            border:'1px solid rgba(255,59,92,0.4)',
            display:'flex', alignItems:'center', gap:12,
          }}>
            <PulseDot color="#FF3B5C" speed="1.2s" size={12}/>
            <div style={{ flex:1 }}>
              <div className="pp-mono" style={{ fontSize:10, color:'#FF3B5C', fontWeight:700, letterSpacing:'0.1em' }}>CRITICAL · RISING</div>
              <div style={{ fontSize:12, color:'var(--text-2)', marginTop:2 }}>
                Active <span className="pp-mono" style={{ color:'var(--text-1)', fontWeight:700 }}>1h 47m</span> · last update <TimeAgo seconds={47}/>
              </div>
            </div>
          </div>

          {/* RSI big stat */}
          <div style={{ display:'flex', gap:10, marginTop:14, alignItems:'stretch' }}>
            <div className="card" style={{ flex:1.4, padding:14 }}>
              <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.1em' }}>RISK SEVERITY INDEX</div>
              <div style={{ display:'flex', alignItems:'baseline', gap:4, marginTop:4 }}>
                <Counter to={87.4} dur={1800} decimals={1} className="glow-text" />
                <span className="pp-mono" style={{ fontSize:13, color:'var(--text-3)' }}>/ 100</span>
              </div>
              <div className="meter" style={{ marginTop:8, '--c':'#FF3B5C' }}><i style={{ width:'87.4%' }}/></div>
              <div style={{ display:'flex', justifyContent:'space-between', marginTop:6 }}>
                <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>+12.4 ↑ 30m</span>
                <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>CONF 0.91</span>
              </div>
            </div>
            <div className="card" style={{ flex:1, padding:14 }}>
              <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.1em' }}>WATER LEVEL</div>
              <div style={{ display:'flex', alignItems:'baseline', gap:3, marginTop:4 }}>
                <span className="pp-mono" style={{ fontSize:30, fontWeight:800 }}><Counter to={4.7} decimals={1}/></span>
                <span className="pp-mono" style={{ fontSize:12, color:'var(--text-3)' }}>m</span>
              </div>
              <div style={{ marginTop:8 }}>
                <Sparkline data={[2.1,2.3,2.6,3.0,3.4,3.9,4.3,4.7]} color="#4D9FFF" w={120} h={28}/>
              </div>
            </div>
          </div>

          {/* mini map */}
          <div style={{ marginTop:14, borderRadius:14, overflow:'hidden', border:'1px solid var(--border)' }}>
            <MapTwinCity height={150} showLabels={false} pins={[
              { x: 290, y: 250, color: '#FF3B5C', type: 'flood', glow: true, speed: '1.2s', size: 14 },
            ]}
            showZone={{ d: 'M 240 240 L 290 230 L 330 250 L 340 280 L 300 290 L 250 280 Z', color: '#FF3B5C' }}
            />
          </div>

          {/* stats grid */}
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8, marginTop:12 }}>
            {[
              ['AFFECTED',  14800, '', 0, '#F5F7FA'],
              ['DISPLACED', 320,   '', 0, '#FF8A3D'],
              ['CONFIRMED', 12,    '', 0, '#FF3B5C'],
              ['UNITS DEPLOYED', 7, ' / 12', 0, '#3DDC97'],
            ].map(([label, n, suf, dec, c]) => (
              <div key={label} className="card" style={{ padding:'10px 12px' }}>
                <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.1em' }}>{label}</div>
                <div style={{ marginTop:4, color: c }}>
                  <span className="pp-mono" style={{ fontSize:22, fontWeight:800 }}><Counter to={n} decimals={dec}/></span>
                  <span className="pp-mono" style={{ fontSize:11, color:'var(--text-3)' }}>{suf}</span>
                </div>
              </div>
            ))}
          </div>

          {/* signal preview */}
          <div className="card" style={{ marginTop:14, padding:0, overflow:'hidden' }}>
            <div style={{ padding:'10px 14px', display:'flex', justifyContent:'space-between', alignItems:'center', borderBottom:'1px solid var(--border)' }}>
              <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.08em' }}>LATEST SIGNALS · 4 NEW</span>
              <span style={{ fontSize:11, color:'var(--sev-info)', fontWeight:600 }}>VIEW ALL →</span>
            </div>
            {[
              { src:'PMD · Sensor', t:'47s', body:'Soan station: 4.7m, +0.18m/h.', mono:true, c:'#4D9FFF' },
              { src:'@rwp_rescue · Tweet', t:'2m', body:'صدر روڈ پر شدید پانی، گاڑیاں پھنسی ہوئی ہیں۔', urdu:true, c:'#B84DFF' },
              { src:'Citizen Tip · 1166', t:'4m', body:'Kashmir Rd jam, water knee-deep near bridge.', c:'#FFD23D' },
            ].map((s, i) => (
              <div key={i} className="signal-in" style={{
                padding:'10px 14px', display:'flex', gap:10,
                borderBottom: i < 2 ? '1px solid var(--border)' : 'none',
                animationDelay: `${i * 0.12}s`,
              }}>
                <div style={{ width:3, alignSelf:'stretch', background:s.c, borderRadius:2, flexShrink:0 }}/>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
                    <span className="pp-mono" style={{ fontSize:9, color:s.c, fontWeight:700, letterSpacing:'0.06em' }}>{s.src.toUpperCase()}</span>
                    <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>{s.t}</span>
                  </div>
                  <div className={s.urdu ? 'pp-urdu' : (s.mono ? 'pp-mono' : '')} style={{ fontSize: s.urdu ? 15 : 12, color:'var(--text-1)', marginTop:3, lineHeight: s.urdu ? 1.8 : 1.4 }}>{s.body}</div>
                </div>
              </div>
            ))}
          </div>

          {/* CTAs */}
          <div style={{ display:'flex', gap:8, marginTop:14, paddingBottom: 30 }}>
            <button className="btn btn-ghost" style={{ flex:1 }}>
              <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6"><path d="M2 8h12M9 3l5 5-5 5" strokeLinecap="round"/></svg>
              TRACE
            </button>
            <button className="btn btn-primary" style={{ flex:1.4, '--c':'#FF3B5C' }}>
              OPEN ACTION CONSOLE
            </button>
          </div>
        </div>
      </div>
      <HomeBar/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 4 · AGENT REASONING TRACE
// ════════════════════════════════════════════════════════════
function ScreenReasoning() {
  const steps = [
    { agent: 'WATCHER', color: '#4D9FFF', t:'17:21:04', conf:0.96, status:'done',
      title:'Detected Soan station threshold breach',
      body:'PMD gauge crossed 4.0m at 17:19 (delta +0.21m/h). 38 corroborating signals from R-Twitter, 7 citizen tips.',
      trace:['PMD-SOAN-3', '@rwp_rescue', '@traffic_isb', '1166 tip #4421'] },
    { agent: 'ANALYST', color: '#B84DFF', t:'17:21:38', conf:0.91, status:'done',
      title:'Scored RSI · classified CRITICAL',
      body:'Population at risk: 14,800 (DSL-2020). Health facilities w/in 2km: 3. Comparative match: 2022 Soan event @ 67% similarity.',
      trace:['POP-GRID-RWP-04', 'HIST-2022-08-Soan'] },
    { agent: 'COORDINATOR', color: '#FFD23D', t:'17:22:09', conf:0.83, status:'thinking',
      title:'Computing optimal reroute and dispatch plan',
      body:'Closing N-5 between Peshawar More ↔ Cantt. Alternate via Murree Rd surcharge: +9 min. Dispatching DG-1, DG-3, Rescue-1122 units.',
      trace:['ROUTE-N5-A', 'UNIT-DG-1', 'UNIT-1122-RWP'] },
    { agent: 'RESPONDER', color: '#3DDC97', t:'—', conf:null, status:'pending',
      title:'Awaiting authorization',
      body:'Will execute: traffic block, public alert (EN/UR/RU), unit dispatch. Estimated effect window: 8–12 min.',
      trace:[] },
  ];

  return (
    <div className="pp-screen">
      <PPStatusBar/>

      {/* nav */}
      <div style={{ display:'flex', alignItems:'center', gap:8, padding:'4px 16px 8px' }}>
        <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
          <svg width="13" height="13" viewBox="0 0 14 14" fill="none" stroke="#94A3B8" strokeWidth="1.8"><path d="M9 2L3 7l6 5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:16, fontWeight:800, letterSpacing:'-0.02em' }}>Reasoning Trace</div>
          <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>FLD-014 · 4 agents · 3 of 4 done</div>
        </div>
        <span className="chip" style={{ '--c':'#FFD23D' }}>
          <AgentDots color="#FFD23D"/> LIVE
        </span>
      </div>

      <div className="pp-scroll" style={{ height:'calc(100% - 100px)', padding:'8px 18px 80px' }}>
        {/* decision banner */}
        <div className="card" style={{ marginBottom:18, padding:14, background:'linear-gradient(135deg, rgba(255,210,61,0.08), rgba(255,210,61,0.01))', border:'1px solid rgba(255,210,61,0.35)' }}>
          <div className="pp-mono" style={{ fontSize:9, color:'#FFD23D', letterSpacing:'0.12em' }}>PENDING DECISION</div>
          <div style={{ fontSize:14, fontWeight:700, marginTop:6, lineHeight:1.35 }}>
            Block N-5 (Peshawar More ↔ Cantt), dispatch DG-1 + 1122, broadcast public alert in EN/UR.
          </div>
          <div style={{ display:'flex', gap:8, marginTop:12 }}>
            <button className="btn btn-ghost" style={{ flex:1, padding:'8px 10px', fontSize:12 }}>HOLD</button>
            <button className="btn btn-primary" style={{ flex:1, '--c':'#3DDC97', padding:'8px 10px', fontSize:12 }}>
              AUTHORIZE
              <span className="kbd" style={{ background:'rgba(0,0,0,0.2)', borderColor:'rgba(0,0,0,0.3)', color:'rgba(10,14,26,0.7)' }}>⌘ ↵</span>
            </button>
          </div>
        </div>

        {/* timeline */}
        <div style={{ position:'relative' }}>
          {/* vertical track */}
          <div style={{ position:'absolute', left:15, top:14, bottom:14, width:1, background:'var(--border)' }}/>

          {steps.map((s, i) => (
            <div key={i} style={{ position:'relative', paddingLeft:46, marginBottom:18 }}>
              {/* agent node */}
              <div style={{
                position:'absolute', left:0, top:0, width:32, height:32, borderRadius:'50%',
                background:'var(--bg-card)',
                border: `1.5px solid ${s.color}`,
                boxShadow: s.status === 'thinking' ? `0 0 16px ${s.color}, 0 0 0 4px ${s.color}22` : 'none',
                display:'grid', placeItems:'center',
                animation: s.status === 'thinking' ? 'pp-breathe 2s ease-in-out infinite' : 'none',
              }}>
                {s.status === 'thinking'
                  ? <AgentDots color={s.color}/>
                  : s.status === 'done'
                  ? <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={s.color} strokeWidth="2"><path d="M3 7l3 3 5-6" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  : <div style={{ width:8, height:8, borderRadius:'50%', background:'var(--border-hi)' }}/>
                }
              </div>
              {/* card */}
              <div style={{ background:'var(--bg-card)', border:`1px solid ${s.status==='thinking' ? s.color+'55' : 'var(--border)'}`, borderRadius:12, padding:'10px 12px' }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
                  <span className="pp-mono" style={{ fontSize:10, color:s.color, fontWeight:700, letterSpacing:'0.08em' }}>{s.agent}</span>
                  <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>{s.t}</span>
                </div>
                <div style={{ fontSize:13, fontWeight:700, marginTop:4, lineHeight:1.3 }}>{s.title}</div>
                <div style={{ fontSize:12, color:'var(--text-2)', marginTop:4, lineHeight:1.45 }}>{s.body}</div>
                {s.trace.length > 0 && (
                  <div style={{ display:'flex', gap:5, flexWrap:'wrap', marginTop:8 }}>
                    {s.trace.map((t, j) => (
                      <span key={j} className="pp-mono" style={{
                        fontSize:9, padding:'2px 6px', background:'var(--bg-elevated)',
                        border:'1px solid var(--border)', borderRadius:4, color:'var(--text-2)',
                      }}>{t}</span>
                    ))}
                  </div>
                )}
                {s.conf !== null && (
                  <div style={{ display:'flex', alignItems:'center', gap:6, marginTop:8 }}>
                    <div className="meter" style={{ flex:1, '--c': s.color }}><i style={{ width: `${s.conf*100}%` }}/></div>
                    <span className="pp-mono" style={{ fontSize:9, color:s.color, fontWeight:700 }}>{(s.conf*100).toFixed(0)}%</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
      <HomeBar/>
    </div>
  );
}

Object.assign(window, { ScreenOnboarding, ScreenLiveMap, ScreenCrisisDetail, ScreenReasoning });
