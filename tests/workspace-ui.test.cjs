// Minimal browser-side static and syntax regression checks for the v1.6 workspace.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const match=html.match(/<script>([\s\S]*?)<\/script>/);
assert(match,'Main JS must remain bundled into the single HTML file');
new vm.Script(match[1],{filename:'ClickFlow-ui.js'});
const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
assert.equal(new Set(ids).size,ids.length,'HTML ids must be unique');
for(const id of [
    'liveMonitorCard','liveCpsChart','liveMonitorValue','floatQuick',
    'profileList','cpsQuickSettings','cpsQuickMode','cpsQuickMin','cpsQuickMax',
    'cpsQuickIntensity','cpsQuickRevert','cpsQuickApply','cpsQuickNotice',
    'page-settings','page-dashboard','page-profiles','page-cps','page-about',
    'desktopShortcutButton','startShortcutButton','uninstallKeep','uninstallAll'
])assert(ids.includes(id),'Missing workspace control: '+id);
for(const pref of ['closeToTray','minimizeToTray','floatShown','liveMonitor',
    'compactChart','floatGraph','floatTopMost'])
    assert(html.includes('data-preference="'+pref+'"'),'Missing desktop preference '+pref);
assert(html.includes("send('quickSettings'"),'Quick settings must use atomic backend command');
assert(html.includes("send('favorite'"),'Favorite actions must use backend');
assert(html.includes("send('reorder'"),'Reorder actions must use backend');
assert(html.includes("send('desktop','float'"),'Floating GUI toggle missing');
assert(html.includes("liveMonitor.samples"),'Live CPS sample collection missing');
const settings=html.indexOf('<section id="page-settings"');
const about=html.indexOf('<section id="page-about"');
assert(settings>0&&settings<about,'Settings must be a separate tab before About');
assert(html.indexOf('id="uninstallAll"')<about,'Uninstaller must move under Settings');
assert(html.indexOf('id="desktopShortcutButton"')<about,'Shortcuts must move under Settings');
assert(html.includes('body.compact #page-settings{display:none!important}'),
    'Compact mode must keep the dashboard-only layout');
assert(ids.includes('compactTop')&&ids.includes('compactStatus'),
    'Compact mode must have its own status banner');
assert(ids.includes('floatOpacitySelect'),'Mini-window opacity preference missing');
assert(html.includes('id="intensityBlock"'),
    'Natural intensity controls must be available in compact mode');
assert(html.includes('body.compact #intensityBlock:not(.hidden){display:block}'),
    'Compact natural intensity must not be hidden');
assert(html.includes('profile-order-row')&&html.includes('profile-order-buttons'),
    'Reorder buttons must have their own responsive footer');
assert(html.includes('profile-move-btn')&&html.includes('Monter le profil')
    &&html.includes('Descendre le profil'),
    'Up/down reorder arrows must have fixed-size accessible controls');
assert(html.includes("send('preference','floatOpacity',value)"),
    'Opacity selector must notify the Windows engine');
assert(html.includes('model.preferences.compactChart'),
    'Compact chart must use its independent preference');
for(const id of ['compactPanel','compactProfileSelect','compactModeSeg',
    'compactIntensitySeg','compactMin','compactMax','compactStop',
    'compactCps','compactClicks','compactCapture','compactCaptureStop',
    'compactCpsChart','compactChartTile','compactHotkey','compactEmergencyKey'])
    assert(ids.includes(id),'Missing dense compact panel control: '+id);
assert(html.includes('body.compact .dashboard{display:none!important}'),
    'Compact mode must hide expanded dashboard rather than shrink large cards');
assert(html.includes('body.compact .compact-panel{display:grid'),
    'Compact mode must have its own responsive card layout');
assert(html.includes("config().mode=value;render();send('set','mode',value)"),
    'Compact mode selector must change real profile mode');
assert(html.includes("config().intensity=value;render();send('set','intensity',value)"),
    'Compact variation selector must change the profile');
assert(html.includes("$('compactStop').onclick"),'Compact stop must be actionable');
assert(html.includes('drawMonitorCanvas'), 'Compact graph must use live CPS buffer');
assert(html.includes("mode.textContent=({fixed:"),
    'Profile mode and intensity must remain in the CPS information line');
assert(html.includes("shortcut.textContent='Activation : '+(p.settings.hotkey||'F6');"),
    'Activation line should only show hotkey');
console.log('Workspace HTML structure, live monitor, settings, profile and quick edit JS syntax passed.');
