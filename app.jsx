// PAK-PULSE · canvas — all screens on a design canvas
// Plus a Tweaks panel for accent/density/severity-color tuning.

const PHONE_W = 390;
const PHONE_H = 844;

// Custom slim phone frame — content uses its own dark status bar so we
// only render the bezel + dynamic island.
function Phone({ children }) {
  return (
    <div style={{
      width: PHONE_W, height: PHONE_H,
      background: '#0A0E1A',
      borderRadius: 52,
      overflow: 'hidden',
      position: 'relative',
      boxShadow: '0 0 0 9px #1a1d24, 0 0 0 10px #2a2d34, 0 30px 70px rgba(0,0,0,0.5)',
    }}>
      {/* dynamic island */}
      <div style={{
        position:'absolute', top:11, left:'50%', transform:'translateX(-50%)',
        width:118, height:34, borderRadius:24, background:'#000', zIndex:80,
      }}/>
      {children}
    </div>
  );
}

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#FF3B5C",
  "density": "comfortable",
  "showLabels": true,
  "monoNumbers": true
}/*EDITMODE-END*/;

function PakPulseTweaks() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  React.useEffect(() => {
    document.documentElement.style.setProperty('--sev-critical', t.accent);
  }, [t.accent]);

  React.useEffect(() => {
    const map = { compact: 0.85, comfortable: 1, roomy: 1.15 };
    document.documentElement.style.setProperty('--pp-density', map[t.density] || 1);
  }, [t.density]);

  return (
    <TweaksPanel>
      <TweakSection label="Critical Glow">
        <TweakColor
          label="Accent"
          value={t.accent}
          onChange={(v) => setTweak('accent', v)}
          options={['#FF3B5C', '#FF6B3D', '#B84DFF', '#4D9FFF', '#3DDC97']}
        />
      </TweakSection>
      <TweakSection label="Console">
        <TweakRadio
          label="Density"
          value={t.density}
          onChange={(v) => setTweak('density', v)}
          options={[
            { value: 'compact',     label: 'Compact' },
            { value: 'comfortable', label: 'Comfy' },
            { value: 'roomy',       label: 'Roomy' },
          ]}
        />
        <TweakToggle
          label="Map labels"
          value={t.showLabels}
          onChange={(v) => setTweak('showLabels', v)}
        />
        <TweakToggle
          label="Monospace numbers"
          value={t.monoNumbers}
          onChange={(v) => setTweak('monoNumbers', v)}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

function App() {
  return (
    <>
      <DesignCanvas>
        <DCSection id="entry" title="01 · ENTRY" subtitle="First-run onboarding · 3 screens">
          <DCArtboard id="ob-1" label="Splash · what is Pak-Pulse" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenOnboarding step={1}/></Phone>
          </DCArtboard>
          <DCArtboard id="ob-2" label="Agent system" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenOnboarding step={2}/></Phone>
          </DCArtboard>
          <DCArtboard id="ob-3" label="Language" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenOnboarding step={3}/></Phone>
          </DCArtboard>
        </DCSection>

        <DCSection id="live" title="02 · LIVE OPS" subtitle="The hero loop — see, understand, decide">
          <DCArtboard id="map" label="Live Crisis Map · Islamabad / Rawalpindi" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenLiveMap/></Phone>
          </DCArtboard>
          <DCArtboard id="detail" label="Crisis Detail · FLD-014" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenCrisisDetail/></Phone>
          </DCArtboard>
          <DCArtboard id="trace" label="Agent Reasoning Trace" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenReasoning/></Phone>
          </DCArtboard>
        </DCSection>

        <DCSection id="intel" title="03 · INTEL & ACTION" subtitle="Raw signals in · dispatch out">
          <DCArtboard id="signals" label="Signal Inbox · multilingual feed" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenSignals/></Phone>
          </DCArtboard>
          <DCArtboard id="action" label="Action Console · reroute, broadcast, dispatch" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenAction/></Phone>
          </DCArtboard>
        </DCSection>

        <DCSection id="meta" title="04 · RETRO & SYSTEM" subtitle="Replay past events · operator settings">
          <DCArtboard id="replay" label="Crisis Replay · timeline scrubber" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenReplay/></Phone>
          </DCArtboard>
          <DCArtboard id="settings" label="Console Settings" width={PHONE_W} height={PHONE_H}>
            <Phone><ScreenSettings/></Phone>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>
      <PakPulseTweaks/>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
