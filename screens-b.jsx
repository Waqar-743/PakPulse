// PAK-PULSE · screens B — Signal Inbox, Action Console, Replay, Settings

// ════════════════════════════════════════════════════════════
// 5 · SIGNAL INBOX — incoming raw signals feed
// ════════════════════════════════════════════════════════════
function ScreenSignals() {
  const signals = [
    { src:'TWITTER',   handle:'@isb_traffic', t:30, urdu:false,
      body:'Heavy queue building on Faizabad Interchange, 200+ vehicles stuck.',
      loc:'ISLAMABAD · FAIZABAD', tag:'TRAFFIC', tagC:'#FFD23D', glow:true, fresh:true },
    { src:'CITIZEN',   handle:'1166 · TIP-4421', t:74, urdu:false,
      body:'Kashmir Rd jam, water knee-deep near bridge. Bachay phans gaye.',
      loc:'RAWALPINDI · KASHMIR RD', tag:'FLOOD', tagC:'#4D9FFF', romanUrdu:true, fresh:true },
    { src:'TWITTER',   handle:'@rwp_rescue', t:142, urdu:true,
      body:'صدر روڈ پر شدید پانی جمع، ٹریفک مکمل بند۔ بچاؤ ٹیم بھیجی جارہی ہے۔',
      bodyEn:'Heavy flooding on Saddar Road, traffic halted. Rescue team being dispatched.',
      loc:'RAWALPINDI · SADDAR', tag:'FLOOD', tagC:'#4D9FFF' },
    { src:'PMD SENSOR', handle:'SOAN-STN-03', t:184, urdu:false, mono:true,
      body:'level=4.71m  delta=+0.18m/h  flow=243 m³/s  threshold=BREACH',
      loc:'RAWALPINDI · SOAN', tag:'TELEMETRY', tagC:'#3DDC97' },
    { src:'TV NEWS',   handle:'GEO @ 17:18', t:240, urdu:false,
      body:'Local administration warns residents of Soan basin to evacuate low-lying areas.',
      loc:'BROADCAST', tag:'MEDIA', tagC:'#94A3B8' },
    { src:'TWITTER',   handle:'@khurram_isl', t:307, urdu:false,
      body:'D-Chowk protest larger than expected — 5,000+ people, three roads blocked.',
      loc:'ISLAMABAD · D-CHOWK', tag:'PROTEST', tagC:'#B84DFF' },
    { src:'WHATSAPP',  handle:'Pak-Pulse · Tipline', t:412, urdu:true,
      body:'سیکٹر I-9 میں آگ لگ گئی ہے، فائر بریگیڈ کا انتظار ہے۔',
      bodyEn:'Fire in Sector I-9, awaiting fire brigade.',
      loc:'ISLAMABAD · I-9', tag:'FIRE', tagC:'#FF3B5C' },
  ];

  return (
    <div className="pp-screen">
      <PPStatusBar/>

      {/* nav */}
      <div style={{ padding:'4px 16px 12px' }}>
        <div style={{ display:'flex', alignItems:'center', gap:8 }}>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:22, fontWeight:800, letterSpacing:'-0.02em' }}>Signal Inbox</div>
            <div style={{ display:'flex', alignItems:'center', gap:6, marginTop:2 }}>
              <PulseDot color="#3DDC97" size={6} speed="2s"/>
              <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.04em' }}>
                <Counter to={2847}/> signals · last hour
              </span>
            </div>
          </div>
          <button style={{ width:36, height:36, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="#94A3B8" strokeWidth="1.6"><path d="M2 4h10M3 7h8M5 10h4" strokeLinecap="round"/></svg>
          </button>
        </div>

        {/* filter row */}
        <div style={{ display:'flex', gap:6, marginTop:14, overflow:'hidden' }}>
          {[
            ['ALL',     '#F5F7FA', 2847],
            ['FLOOD',   '#4D9FFF', 412],
            ['TRAFFIC', '#FFD23D', 681],
            ['PROTEST', '#B84DFF', 184],
            ['FIRE',    '#FF3B5C', 22],
          ].map(([label, c, n], i) => (
            <button key={label} style={{
              padding:'5px 9px', borderRadius:7,
              background: i===0 ? 'var(--bg-card-hi)' : 'transparent',
              border: `1px solid ${i===0 ? c+'66' : 'var(--border)'}`,
              color: i===0 ? c : 'var(--text-2)',
              fontFamily:'JetBrains Mono', fontSize:10, fontWeight:700, letterSpacing:'0.04em',
              display:'flex', alignItems:'center', gap:5,
            }}>
              {label} <span style={{ opacity:.55, fontWeight:500 }}>{n.toLocaleString()}</span>
            </button>
          ))}
        </div>

        {/* sources row */}
        <div style={{ display:'flex', gap:5, marginTop:8 }}>
          {[
            ['TW', 'Twitter'],
            ['1166', 'Tip Line'],
            ['PMD', 'Sensors'],
            ['WA', 'WhatsApp'],
            ['TV', 'Broadcast'],
          ].map(([k, l]) => (
            <span key={k} className="pp-mono" style={{
              fontSize:9, padding:'3px 6px', background:'var(--bg-card)',
              border:'1px solid var(--border)', borderRadius:5, color:'var(--text-3)', letterSpacing:'0.04em',
            }}>{k}</span>
          ))}
          <span style={{ flex:1 }}/>
          <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', alignSelf:'center' }}>SORT · NEW ↓</span>
        </div>
      </div>

      <div className="pp-scroll" style={{ height:'calc(100% - 200px)', paddingBottom:60 }}>
        <div style={{ padding:'0 16px', display:'flex', flexDirection:'column', gap:8 }}>
          {/* live "arriving now" header */}
          <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:2 }}>
            <PulseDot color="#3DDC97" size={6} speed="1.6s"/>
            <span className="pp-mono" style={{ fontSize:9, color:'#3DDC97', fontWeight:700, letterSpacing:'0.1em' }}>ARRIVING · LAST 5 MIN</span>
            <div style={{ flex:1, height:1, background:'linear-gradient(90deg, rgba(61,220,151,0.4), transparent)' }}/>
          </div>

          {signals.map((s, i) => (
            <div key={i} className={'card signal-in ' + (s.glow ? 'signal-glow' : '')}
              style={{
                padding:0, overflow:'hidden',
                animationDelay: `${i * 0.08}s`,
                '--c': s.tagC,
              }}>
              <div style={{ display:'flex' }}>
                <div style={{ width:3, background:s.tagC, flexShrink:0 }}/>
                <div style={{ flex:1, padding:'10px 12px' }}>
                  <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:6 }}>
                    <span className="pp-mono" style={{
                      fontSize:9, padding:'1.5px 5px', background:s.tagC + '22',
                      color:s.tagC, fontWeight:700, letterSpacing:'0.06em', borderRadius:3,
                    }}>{s.tag}</span>
                    <span className="pp-mono" style={{ fontSize:10, color:'var(--text-2)', fontWeight:600 }}>{s.src}</span>
                    <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>· {s.handle}</span>
                    <span style={{ flex:1 }}/>
                    {s.fresh && <PulseDot color={s.tagC} size={5} speed="1.6s"/>}
                    <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>
                      <TimeAgo seconds={s.t}/>
                    </span>
                  </div>

                  <div className={s.urdu ? 'pp-urdu' : (s.mono ? 'pp-mono' : '')} style={{
                    fontSize: s.urdu ? 16 : (s.mono ? 11 : 13),
                    lineHeight: s.urdu ? 1.85 : 1.4,
                    color:'var(--text-1)',
                  }}>{s.body}</div>
                  {s.bodyEn && (
                    <div style={{ fontSize:11, color:'var(--text-3)', marginTop:4, fontStyle:'italic' }}>
                      "{s.bodyEn}"
                    </div>
                  )}
                  {s.romanUrdu && (
                    <div style={{ marginTop:4 }}>
                      <span className="pp-mono" style={{ fontSize:8, padding:'1px 4px', background:'var(--bg-card-hi)', border:'1px solid var(--border)', color:'var(--text-3)', borderRadius:3, fontWeight:600 }}>ROMAN UR</span>
                    </div>
                  )}

                  <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:8 }}>
                    <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.06em' }}>
                      ◉ {s.loc}
                    </span>
                    <span style={{ flex:1 }}/>
                    <button style={{ background:'transparent', border:'none', color:'var(--text-3)', fontSize:11, padding:0, fontWeight:600 }}>LINK →</button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="signals"/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 6 · ACTION CONSOLE — execute decision
// ════════════════════════════════════════════════════════════
function ScreenAction() {
  const [tab, setTab] = useStateA('reroute');
  const [lang, setLang] = useStateA('ur');

  return (
    <div className="pp-screen">
      <PPStatusBar/>

      {/* nav */}
      <div style={{ display:'flex', alignItems:'center', gap:8, padding:'4px 16px 8px' }}>
        <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
          <svg width="13" height="13" viewBox="0 0 14 14" fill="none" stroke="#94A3B8" strokeWidth="1.8"><path d="M9 2L3 7l6 5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:16, fontWeight:800, letterSpacing:'-0.02em' }}>Action Console</div>
          <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>FLD-014 · 3 actions queued</div>
        </div>
        <span className="chip" style={{ '--c':'#FF3B5C' }}><span className="dot"/>ARMED</span>
      </div>

      {/* hero map with reroute */}
      <div style={{ position:'relative', borderRadius:'0', overflow:'hidden', height:200 }}>
        <MapTwinCity height={200} showLabels={false} pins={[
          { x: 290, y: 250, color: '#FF3B5C', type: 'flood', glow:true, speed: '1.2s', size: 12 },
        ]}
        showZone={{ d: 'M 240 240 L 290 230 L 330 250 L 340 280 L 300 290 L 250 280 Z', color: '#FF3B5C' }}
        showRoute={{
          from: 'M 240 235 L 280 250 L 320 245 L 360 260',
          to:   'M 240 235 C 270 215, 300 200, 330 215 S 370 240, 360 260',
        }}/>
        <div style={{ position:'absolute', left:12, bottom:12, display:'flex', gap:6 }}>
          <span className="pp-mono" style={{ padding:'3px 7px', background:'rgba(255,59,92,0.18)', border:'1px solid rgba(255,59,92,0.4)', borderRadius:5, fontSize:9, fontWeight:700, color:'#FF3B5C', letterSpacing:'0.06em' }}>● BLOCKED · N-5</span>
          <span className="pp-mono" style={{ padding:'3px 7px', background:'rgba(61,220,151,0.18)', border:'1px solid rgba(61,220,151,0.4)', borderRadius:5, fontSize:9, fontWeight:700, color:'#3DDC97', letterSpacing:'0.06em' }}>↗ NEW · MURREE RD</span>
        </div>
      </div>

      {/* action tabs */}
      <div style={{ display:'flex', borderBottom:'1px solid var(--border)', padding:'0 16px' }}>
        {[
          ['reroute','REROUTE', 1],
          ['alert','BROADCAST', 1],
          ['dispatch','DISPATCH', 3],
        ].map(([id, label, n]) => (
          <button key={id} onClick={() => setTab(id)} style={{
            flex:1, padding:'12px 0', background:'transparent', border:'none',
            color: tab===id ? 'var(--text-1)' : 'var(--text-3)',
            fontFamily:'JetBrains Mono', fontSize:11, fontWeight:700, letterSpacing:'0.08em',
            borderBottom: `2px solid ${tab===id ? 'var(--sev-critical)' : 'transparent'}`,
            display:'flex', alignItems:'center', justifyContent:'center', gap:6,
            cursor:'pointer',
          }}>
            {label}
            <span style={{ padding:'1px 5px', background:tab===id?'var(--sev-critical)':'var(--bg-card)', color:tab===id?'#0A0E1A':'var(--text-3)', borderRadius:8, fontSize:9, fontWeight:800 }}>{n}</span>
          </button>
        ))}
      </div>

      <div className="pp-scroll" style={{ height:'calc(100% - 410px)', padding:'14px 16px 80px' }}>
        {tab === 'reroute' && (
          <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
            <div className="card" style={{ padding:14 }}>
              <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
                <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.1em' }}>ROUTE PROPOSAL</span>
                <span className="pp-mono" style={{ fontSize:10, color:'#3DDC97', fontWeight:700 }}>CONF 0.87</span>
              </div>
              <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                <div style={{ flex:1 }}>
                  <div className="pp-mono" style={{ fontSize:11, color:'var(--text-2)', textDecoration:'line-through', textDecorationColor:'#FF3B5C' }}>N-5 · Peshawar More → Cantt</div>
                  <div style={{ display:'flex', alignItems:'center', gap:4, marginTop:6 }}>
                    <svg width="12" height="12" viewBox="0 0 14 14" fill="none" stroke="#3DDC97" strokeWidth="1.8"><path d="M2 7h10M7 2l5 5-5 5" strokeLinecap="round"/></svg>
                    <div className="pp-mono" style={{ fontSize:12, color:'#3DDC97', fontWeight:700 }}>VIA MURREE RD · ALT</div>
                  </div>
                </div>
                <div style={{ textAlign:'right' }}>
                  <div className="pp-mono" style={{ fontSize:18, fontWeight:800, color:'#FF8A3D' }}>+9<span style={{ fontSize:11, color:'var(--text-3)', fontWeight:600 }}> min</span></div>
                  <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.06em' }}>EXPECTED DELAY</div>
                </div>
              </div>
              <div style={{ marginTop:10, paddingTop:10, borderTop:'1px solid var(--border)', display:'flex', gap:14 }}>
                <div>
                  <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>VEHICLES/H</div>
                  <div className="pp-mono" style={{ fontSize:13, fontWeight:700 }}><Counter to={2840}/></div>
                </div>
                <div>
                  <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>SEGMENTS</div>
                  <div className="pp-mono" style={{ fontSize:13, fontWeight:700 }}>4</div>
                </div>
                <div>
                  <div className="pp-mono" style={{ fontSize:9, color:'var(--text-3)' }}>SIGNAGE</div>
                  <div className="pp-mono" style={{ fontSize:13, fontWeight:700, color:'#3DDC97' }}>7 / 7</div>
                </div>
              </div>
            </div>

            <div className="card" style={{ padding:'10px 12px', display:'flex', alignItems:'center', gap:10 }}>
              <div style={{ width:6, height:6, borderRadius:'50%', background:'#FFD23D', boxShadow:'0 0 6px #FFD23D' }}/>
              <span className="pp-mono" style={{ fontSize:11, color:'var(--text-2)' }}>Adjacent fallback: G.T. Rd via Kallar Syedan (+22 min)</span>
            </div>
          </div>
        )}

        {tab === 'alert' && (
          <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
            {/* language toggle */}
            <div style={{ display:'flex', gap:4, background:'var(--bg-card)', border:'1px solid var(--border)', padding:3, borderRadius:10 }}>
              {[['en','EN'],['ur','اردو'],['ru','Roman Ur']].map(([k, l]) => (
                <button key={k} onClick={() => setLang(k)} style={{
                  flex:1, padding:'7px 0', borderRadius:7, background: lang===k ? 'var(--bg-card-hi)' : 'transparent',
                  border:'none', color: lang===k ? 'var(--text-1)' : 'var(--text-3)',
                  fontFamily: k==='ur' ? 'Noto Nastaliq Urdu' : 'Plus Jakarta Sans',
                  fontSize: k==='ur' ? 16 : 12, fontWeight:700, cursor:'pointer',
                }}>{l}</button>
              ))}
            </div>

            <div className="card" style={{ padding:0, overflow:'hidden' }}>
              <div style={{ padding:'8px 12px', display:'flex', justifyContent:'space-between', borderBottom:'1px solid var(--border)' }}>
                <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.1em' }}>BROADCAST DRAFT · 3 CHANNELS</span>
                <span className="pp-mono" style={{ fontSize:9, color:'#FFD23D' }}>UNSENT</span>
              </div>
              <div style={{ padding:'14px 14px 12px' }}>
                {lang==='en' && (
                  <div style={{ fontSize:14, lineHeight:1.45 }}>
                    <strong>FLOOD ALERT — Rawalpindi.</strong> Soan riverbank breached. N-5 from Peshawar More to Cantt is closed. Use Murree Rd. Residents near Soan basin: move to higher ground. <span style={{ color:'var(--text-3)' }}>— NDMA · 17:24</span>
                  </div>
                )}
                {lang==='ur' && (
                  <div className="pp-urdu" style={{ fontSize:18, lineHeight:2, color:'var(--text-1)' }}>
                    سیلابی الرٹ — راولپنڈی۔ سون ندی کے کنارے ٹوٹ گئے ہیں۔ پشاور موڑ سے چھاؤنی تک این-5 بند ہے۔ مری روڈ استعمال کریں۔ سون بیسن کے رہائشی فوراً اونچی جگہ پر منتقل ہوں۔
                  </div>
                )}
                {lang==='ru' && (
                  <div style={{ fontSize:14, lineHeight:1.55, color:'var(--text-1)' }}>
                    <strong>SAILABI ALERT — Rawalpindi.</strong> Soan nadi ke kinare toot gaye hain. Peshawar Mor se Cantt tak N-5 band hai. Murree Road istemal karein. Soan basin ke rehaishi foran unchi jagah par muntaqil hon.
                  </div>
                )}
              </div>
              <div style={{ padding:'10px 12px', background:'var(--bg-elevated)', display:'flex', gap:6, flexWrap:'wrap', borderTop:'1px solid var(--border)' }}>
                {[['SMS','#3DDC97',true],['CELL B-CAST','#3DDC97',true],['RADIO','#FFD23D',true],['TV TICKER','#94A3B8',false]].map(([n,c,on]) => (
                  <span key={n} className="pp-mono" style={{
                    fontSize:9, padding:'3px 7px', borderRadius:4,
                    background: on ? c+'22' : 'transparent',
                    border:`1px solid ${on ? c+'55' : 'var(--border)'}`,
                    color: on ? c : 'var(--text-3)', fontWeight:700, letterSpacing:'0.06em',
                  }}>{on?'●':'○'} {n}</span>
                ))}
              </div>
            </div>
            <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', textAlign:'center' }}>
              EST. REACH · <span style={{ color:'var(--text-1)', fontWeight:700 }}>1.4M</span> DEVICES
            </div>
          </div>
        )}

        {tab === 'dispatch' && (
          <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
            {[
              { id:'DG-1',   name:'District Govt · Rescue', eta:7,  units:2, c:'#3DDC97', status:'EN ROUTE' },
              { id:'1122-R', name:'Rescue 1122 · Rwp Hub',  eta:12, units:3, c:'#FFD23D', status:'STANDBY' },
              { id:'NDMA-3', name:'NDMA · Mobile Cmd',      eta:23, units:1, c:'#94A3B8', status:'STAGING' },
            ].map((u) => (
              <div key={u.id} className="card" style={{ padding:'10px 12px', display:'flex', alignItems:'center', gap:12 }}>
                <PulseDot color={u.c} size={8} speed="1.6s"/>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ display:'flex', alignItems:'baseline', gap:8 }}>
                    <span className="pp-mono" style={{ fontSize:10, color:u.c, fontWeight:700 }}>{u.id}</span>
                    <span style={{ fontSize:13, fontWeight:700 }}>{u.name}</span>
                  </div>
                  <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', marginTop:2 }}>
                    {u.units} unit{u.units>1?'s':''} · {u.status}
                  </div>
                </div>
                <div style={{ textAlign:'right' }}>
                  <div className="pp-mono" style={{ fontSize:16, fontWeight:800, color:u.c }}>{u.eta}<span style={{ fontSize:10, fontWeight:600, color:'var(--text-3)' }}>m</span></div>
                  <div className="pp-mono" style={{ fontSize:8, color:'var(--text-3)', letterSpacing:'0.06em' }}>ETA</div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* execute */}
      <div style={{
        position:'absolute', bottom:0, left:0, right:0,
        padding:'14px 16px 30px',
        background:'rgba(10,14,26,0.92)',
        backdropFilter:'blur(20px)',
        borderTop:'1px solid var(--border)',
      }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10 }}>
          <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.08em' }}>3 ACTIONS · WILL DEPLOY IN 8s</span>
          <span className="pp-mono" style={{ fontSize:10, color:'#3DDC97', fontWeight:700 }}>SIM MODE</span>
        </div>
        <button className="btn btn-primary" style={{ width:'100%', '--c':'#FF3B5C', padding:'14px 16px', fontSize:13, letterSpacing:'0.06em' }}>
          EXECUTE ALL · HOLD TO CONFIRM
          <span className="kbd" style={{ background:'rgba(0,0,0,0.2)', borderColor:'rgba(0,0,0,0.3)', color:'rgba(10,14,26,0.7)' }}>HOLD ⌘</span>
        </button>
      </div>
      <HomeBar/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 7 · CRISIS REPLAY / HISTORY
// ════════════════════════════════════════════════════════════
function ScreenReplay() {
  const events = [
    { t:'17:18', label:'Threshold breach · Soan-03', c:'#FFD23D' },
    { t:'17:21', label:'WATCHER detected · 38 corroborating signals', c:'#4D9FFF' },
    { t:'17:22', label:'ANALYST · RSI=87.4 · CRITICAL', c:'#B84DFF' },
    { t:'17:23', label:'COORDINATOR · reroute computed', c:'#FFD23D' },
    { t:'17:28', label:'Public alert broadcast · 1.4M devices', c:'#3DDC97' },
    { t:'17:34', label:'DG-1 on scene · evacuation started', c:'#3DDC97' },
  ];
  const scrubT = 70; // % of timeline

  return (
    <div className="pp-screen">
      <PPStatusBar/>

      <div style={{ padding:'4px 16px 8px', display:'flex', alignItems:'center', gap:8 }}>
        <button style={{ width:34, height:34, borderRadius:10, background:'var(--bg-card)', border:'1px solid var(--border)', display:'grid', placeItems:'center' }}>
          <svg width="13" height="13" viewBox="0 0 14 14" fill="none" stroke="#94A3B8" strokeWidth="1.8"><path d="M9 2L3 7l6 5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </button>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:16, fontWeight:800, letterSpacing:'-0.02em' }}>Crisis Replay</div>
          <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>FLD-014 · 22 AUG · 17:18–19:05 PKT</div>
        </div>
        <span className="chip" style={{ '--c':'#3DDC97' }}><span className="dot"/>RESOLVED</span>
      </div>

      {/* map with replay sweep */}
      <div style={{ position:'relative' }}>
        <MapTwinCity height={210} replay showLabels={false} pins={[
          { x: 290, y: 250, color: '#FF3B5C', type: 'flood', glow:true, speed:'1.4s', size: 12, label:'T+13m' },
          { x: 245, y: 235, color: '#FF8A3D', speed:'2.4s', size: 8 },
          { x: 320, y: 260, color: '#FFD23D', speed:'2.8s', size: 8 },
        ]}
        showZone={{ d: 'M 240 240 L 290 230 L 330 250 L 340 280 L 300 290 L 250 280 Z', color: '#FF3B5C' }}
        showRoute={{
          from: 'M 240 235 L 280 250 L 320 245 L 360 260',
          to:   'M 240 235 C 270 215, 300 200, 330 215 S 370 240, 360 260',
        }}/>
        <div style={{ position:'absolute', top:10, left:10, padding:'4px 8px', background:'rgba(10,14,26,0.8)', border:'1px solid var(--border)', borderRadius:6 }}>
          <span className="pp-mono" style={{ fontSize:9, color:'var(--text-3)', letterSpacing:'0.06em' }}>SHOWING</span>
          <span className="pp-mono" style={{ fontSize:11, color:'var(--text-1)', fontWeight:700, marginLeft:6 }}>T+13:24</span>
        </div>
      </div>

      {/* scrubber */}
      <div style={{ padding:'14px 18px 6px' }}>
        <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8 }}>
          <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>17:18:00</span>
          <span className="pp-mono" style={{ fontSize:13, fontWeight:800, color:'var(--text-1)' }}>17:31:24</span>
          <span className="pp-mono" style={{ fontSize:10, color:'var(--text-3)' }}>19:05:00</span>
        </div>
        <div style={{ position:'relative', height:30 }}>
          {/* track */}
          <div style={{ position:'absolute', left:0, right:0, top:14, height:3, background:'var(--bg-card-hi)', borderRadius:2 }}/>
          {/* progress */}
          <div style={{ position:'absolute', left:0, top:14, height:3, width:`${scrubT}%`, background:'linear-gradient(90deg, #FF3B5C, #FF8A3D, #FFD23D)', borderRadius:2, boxShadow:'0 0 8px rgba(255,138,61,0.6)' }}/>
          {/* event ticks */}
          {[5,18,22,28,55,75].map((p, i) => (
            <div key={i} style={{ position:'absolute', left:`${p}%`, top:8, width:2, height:14, background:'#94A3B8', opacity:.5 }}/>
          ))}
          {/* head */}
          <div style={{ position:'absolute', left:`${scrubT}%`, top:6, width:14, height:14, borderRadius:'50%', background:'#FF8A3D', boxShadow:'0 0 12px #FF8A3D, 0 0 0 3px rgba(10,14,26,0.9)', transform:'translateX(-50%)' }}/>
        </div>

        {/* transport */}
        <div style={{ display:'flex', alignItems:'center', justifyContent:'center', gap:14, marginTop:6 }}>
          <button style={{ width:32, height:32, borderRadius:8, background:'transparent', border:'1px solid var(--border)', display:'grid', placeItems:'center', color:'var(--text-2)' }}>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="currentColor"><path d="M3 1v9M9 1L4 5.5 9 10"/></svg>
          </button>
          <button style={{ width:42, height:42, borderRadius:'50%', background:'var(--sev-critical)', border:'none', display:'grid', placeItems:'center', boxShadow:'0 0 16px rgba(255,59,92,0.5)', color:'#0A0E1A' }}>
            <svg width="13" height="13" viewBox="0 0 11 11" fill="currentColor"><path d="M2 1h2v9H2zM7 1h2v9H7z"/></svg>
          </button>
          <button style={{ width:32, height:32, borderRadius:8, background:'transparent', border:'1px solid var(--border)', display:'grid', placeItems:'center', color:'var(--text-2)' }}>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="currentColor"><path d="M8 1v9M2 1l5 4.5L2 10"/></svg>
          </button>
          <div style={{ flex:1 }}/>
          <span className="pp-mono" style={{ fontSize:11, color:'var(--text-2)' }}>2× SPEED</span>
        </div>
      </div>

      {/* event log */}
      <div className="pp-scroll" style={{ height:'calc(100% - 470px)', padding:'8px 18px 80px' }}>
        <div style={{ position:'relative' }}>
          <div style={{ position:'absolute', left:5, top:6, bottom:10, width:1, background:'var(--border)' }}/>
          {events.map((e, i) => (
            <div key={i} style={{ position:'relative', paddingLeft:22, paddingBottom:10 }}>
              <div style={{ position:'absolute', left:0, top:5, width:11, height:11, borderRadius:'50%', background:e.c, border:'2px solid var(--bg-base)', boxShadow:`0 0 8px ${e.c}66` }}/>
              <div style={{ display:'flex', alignItems:'baseline', gap:8 }}>
                <span className="pp-mono" style={{ fontSize:11, color:e.c, fontWeight:700 }}>{e.t}</span>
                <span style={{ fontSize:12, color:'var(--text-1)' }}>{e.label}</span>
              </div>
            </div>
          ))}
        </div>

        {/* outcome stats */}
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3, 1fr)', gap:8, marginTop:8 }}>
          <div className="card" style={{ padding:10 }}>
            <div className="pp-mono" style={{ fontSize:8, color:'var(--text-3)', letterSpacing:'0.08em' }}>DETECT → ALERT</div>
            <div className="pp-mono" style={{ fontSize:18, fontWeight:800, color:'#3DDC97' }}>10m 24s</div>
          </div>
          <div className="card" style={{ padding:10 }}>
            <div className="pp-mono" style={{ fontSize:8, color:'var(--text-3)', letterSpacing:'0.08em' }}>EVACUATED</div>
            <div className="pp-mono" style={{ fontSize:18, fontWeight:800 }}>2,184</div>
          </div>
          <div className="card" style={{ padding:10 }}>
            <div className="pp-mono" style={{ fontSize:8, color:'var(--text-3)', letterSpacing:'0.08em' }}>CASUALTIES</div>
            <div className="pp-mono" style={{ fontSize:18, fontWeight:800, color:'#FF3B5C' }}>0</div>
          </div>
        </div>
      </div>

      <TabBar active="history"/>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 8 · SETTINGS
// ════════════════════════════════════════════════════════════
function ScreenSettings() {
  const Row = ({ label, value, icon, danger, c='#94A3B8', last }) => (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px', borderBottom: last ? 'none' : '1px solid var(--border)' }}>
      <div style={{ width:28, height:28, borderRadius:7, background:c+'22', display:'grid', placeItems:'center', color:c, flexShrink:0 }}>{icon}</div>
      <span style={{ flex:1, fontSize:14, color: danger ? '#FF3B5C' : 'var(--text-1)' }}>{label}</span>
      {value && <span className="pp-mono" style={{ fontSize:12, color:'var(--text-3)' }}>{value}</span>}
      <svg width="7" height="11" viewBox="0 0 7 11" fill="none" stroke="var(--text-4)" strokeWidth="1.6" strokeLinecap="round"><path d="M1 1l4.5 4.5L1 10"/></svg>
    </div>
  );
  const Toggle = ({ label, on, icon, c='#94A3B8', last }) => (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px', borderBottom: last ? 'none' : '1px solid var(--border)' }}>
      <div style={{ width:28, height:28, borderRadius:7, background:c+'22', display:'grid', placeItems:'center', color:c, flexShrink:0 }}>{icon}</div>
      <span style={{ flex:1, fontSize:14 }}>{label}</span>
      <div style={{
        width:38, height:22, borderRadius:11,
        background: on ? '#3DDC97' : 'var(--bg-card-hi)',
        border: `1px solid ${on ? '#3DDC97' : 'var(--border)'}`,
        position:'relative', transition:'all .2s',
        boxShadow: on ? '0 0 10px rgba(61,220,151,0.4)' : 'none',
      }}>
        <div style={{ position:'absolute', top:1.5, left: on ? 17.5 : 1.5, width:17, height:17, borderRadius:'50%', background:'#fff', transition:'left .2s', boxShadow:'0 1px 3px rgba(0,0,0,0.4)' }}/>
      </div>
    </div>
  );

  return (
    <div className="pp-screen">
      <PPStatusBar/>

      <div style={{ padding:'4px 18px 12px' }}>
        <div style={{ fontSize:22, fontWeight:800, letterSpacing:'-0.02em' }}>Console</div>
        <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', marginTop:2 }}>OPERATOR · maira.zafar@ndma.gov.pk</div>
      </div>

      <div className="pp-scroll" style={{ height:'calc(100% - 160px)', padding:'0 16px 80px' }}>

        {/* operator card */}
        <div className="card" style={{ padding:14, display:'flex', alignItems:'center', gap:12, marginBottom:18 }}>
          <div style={{ width:48, height:48, borderRadius:24, background:'linear-gradient(135deg,#4D9FFF,#B84DFF)', display:'grid', placeItems:'center', fontFamily:'Plus Jakarta Sans', fontWeight:800, fontSize:18, color:'#0A0E1A' }}>MZ</div>
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontSize:15, fontWeight:700 }}>Maira Zafar</div>
            <div style={{ fontSize:11, color:'var(--text-3)', marginTop:2 }}>NDMA · Coord Cell · Tier 2</div>
            <div style={{ marginTop:5, display:'flex', gap:5 }}>
              <span className="chip" style={{ '--c':'#3DDC97' }}><span className="dot"/>AUTH</span>
              <span className="chip" style={{ '--c':'#FFD23D' }}>SIM MODE</span>
            </div>
          </div>
        </div>

        {/* language */}
        <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.1em', margin:'0 4px 8px' }}>LANGUAGE & RENDERING</div>
        <div className="card" style={{ padding:14 }}>
          <div style={{ display:'flex', gap:6 }}>
            {[
              ['en','English','Aa','#F5F7FA'],
              ['ur','اردو','ا','#FFD23D'],
              ['ru','Roman Ur','Aa', '#94A3B8'],
            ].map(([k, l, glyph, c], i) => (
              <button key={k} style={{
                flex:1, padding:'12px 0', borderRadius:10,
                background: i===1 ? 'var(--bg-card-hi)' : 'transparent',
                border: `1px solid ${i===1 ? c+'66' : 'var(--border)'}`,
                color: 'var(--text-1)',
                display:'flex', flexDirection:'column', alignItems:'center', gap:4,
              }}>
                <span style={{ fontSize:22, fontFamily: k==='ur'?'Noto Nastaliq Urdu':'Plus Jakarta Sans', fontWeight:700, color: i===1 ? c : 'var(--text-2)' }}>{glyph}</span>
                <span className="pp-mono" style={{ fontSize:10, fontWeight:700, letterSpacing:'0.06em', color:'var(--text-2)' }}>{l}</span>
              </button>
            ))}
          </div>
          <div style={{ marginTop:10, padding:8, background:'var(--bg-elevated)', borderRadius:8, fontSize:11, color:'var(--text-3)', display:'flex', alignItems:'center', gap:6 }}>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="#94A3B8"><circle cx="5.5" cy="5.5" r="5" opacity=".3"/><path d="M5.5 3v3M5.5 8v.5" stroke="#94A3B8" strokeWidth="1.2" strokeLinecap="round"/></svg>
            Urdu rendered in <span style={{ fontFamily:'Noto Nastaliq Urdu', color:'var(--text-1)', fontWeight:600 }}> نستعلیق</span> · never transliterated.
          </div>
        </div>

        {/* notifications */}
        <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.1em', margin:'18px 4px 8px' }}>ALERTS</div>
        <div className="card" style={{ padding:0 }}>
          <Toggle label="Critical events · push"  on={true}
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M3 6a4 4 0 0 1 8 0v3l1 2H2l1-2zM6 12.5a1 1 0 0 0 2 0"/></svg>}
            c="#FF3B5C"/>
          <Toggle label="High severity · push"     on={true}
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M7 1l6 12H1L7 1zM7 5v4M7 11v.5" strokeLinecap="round"/></svg>}
            c="#FF8A3D"/>
          <Toggle label="Moderate · in-app only"   on={false}
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="7" cy="7" r="5"/><path d="M7 4v3l2 1"/></svg>}
            c="#FFD23D"/>
          <Toggle label="Haptic feedback"          on={true}
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M5 2v10M9 4v6M3 5v4M11 5v4M1 6v2M13 6v2"/></svg>}
            c="#3DDC97"
            last/>
        </div>

        {/* console */}
        <div className="pp-mono" style={{ fontSize:10, color:'var(--text-3)', letterSpacing:'0.1em', margin:'18px 4px 8px' }}>CONSOLE</div>
        <div className="card" style={{ padding:0 }}>
          <Row label="Region" value="ISB · RWP"  c="#4D9FFF"
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M7 1c2.5 0 4.5 2 4.5 4.5C11.5 9 7 13 7 13S2.5 9 2.5 5.5C2.5 3 4.5 1 7 1z"/><circle cx="7" cy="5.5" r="1.5"/></svg>}/>
          <Row label="Data sources" value="14 active" c="#B84DFF"
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><ellipse cx="7" cy="3.5" rx="5" ry="2"/><path d="M2 3.5v7c0 1.1 2.2 2 5 2s5-.9 5-2v-7"/></svg>}/>
          <Row label="Theme" value="DARK · BLUE" c="#FFD23D"
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M11 8a5 5 0 0 1-6-6 5 5 0 1 0 6 6z"/></svg>}/>
          <Row label="Map tiles" value="OFFLINE · 720MB" c="#3DDC97"
            icon={<svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M1 3.5l4-1.5 4 1.5 4-1.5v8l-4 1.5-4-1.5-4 1.5zM5 2v9M9 3.5v9"/></svg>} last/>
        </div>

        <div style={{ textAlign:'center', marginTop:24 }}>
          <Wordmark size={13} color="var(--text-3)"/>
          <div className="pp-mono" style={{ fontSize:9, color:'var(--text-4)', marginTop:6, letterSpacing:'0.1em' }}>v0.18.3 · BUILD 4421 · 22-AUG-2025</div>
        </div>
      </div>

      <TabBar active="me"/>
    </div>
  );
}

Object.assign(window, { ScreenSignals, ScreenAction, ScreenReplay, ScreenSettings });
