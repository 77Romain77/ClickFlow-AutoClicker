const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const src=html.match(/<script>([\s\S]*?)<\/script>/);
assert(src,'Integrated UI JavaScript missing');
new vm.Script(src[1],{filename:'ClickFlow v1.9 UI'});
const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
assert.equal(new Set(ids).size,ids.length,'All IDs must remain unique');
const settings=html.slice(html.indexOf('<section id="page-settings"'),html.indexOf('<section id="page-about"'));
assert.equal((settings.match(/<details class="settings-group"/g)||[]).length,7,
    'General, diagnostics, overlay, global shortcuts, Windows shortcuts, backup and maintenance need separate groups');
const labels=['Général','Diagnostics et détection souris','Overlay','Raccourcis globaux','Raccourcis Windows',
    'Sauvegarde complète','Maintenance'];
assert(html.includes('Automatique (Raw Input + secours, recommandé)')
    && html.includes('Événementielle (Raw Input requis au démarrage)')
    && html.includes('Classique (vérification périodique)'),
    'The modes must be explained without experimental labels');
assert(!html.includes('Raw Input reste expérimental'),
    'Old experimental label should be removed');
assert(html.includes("Moteur : ") && html.includes('GetKeyState : ')
    && html.includes('UP Raw pendant maintien physique')
    && html.includes('La vérification physique conserve le maintien'),
    'Gate diagnostics should expose Raw Input versus GetKeyState disagreement');
assert(html.includes('Messages Raw Input reçus') && html.includes('aucun message reçu'),
    'Raw Input status must report missing real events instead of only registration');
assert(html.includes('id="mouseDetectionMode"') && html.includes('id="gateMethodCps"')
    && html.includes('id="gateMethodSettings"'), 'Mouse detection selector and real method status must be visible');
assert(html.includes("send('preference'") && html.includes("overlaySetPreference('mouseDetectionMode'"),
    'Mouse detection mode must be sent to AutoHotkey backend');
assert.equal((html.match(/data-preference="diagnosticsEnabled"/g)||[]).length,2,
    'Latency toggle must be visible in Test CPS and Settings');
assert.equal((html.match(/data-preference="gateDebugEnabled"/g)||[]).length,2,
    'Detection debug toggle must be visible in Test CPS and Settings');
assert(html.includes('id="gateMethodCpsPanel" class="cps-last-wrap hidden"')
    && html.includes('id="gateMethodSettings"')
    && html.includes("if(!model.preferences.gateDebugEnabled)return;"),
    'Detailed detection diagnostics must be optional');
for(const name of labels)
    assert(settings.includes('<summary>'+name),
        'Missing collapsible settings category '+name);
for(const suffix of ['Next','Previous','Overlay','Test','Open']){
    for(const prefix of ['globalCapture','globalClear','globalKey']){
        assert(ids.includes(prefix+suffix),'Global hotkey action missing '+prefix+suffix);
    }
}
assert.equal((html.match(/class="kbd">Aucun<\/span>/g)||[]).length,5,
    'Every optional hotkey must be unassigned by default');
for(const id of ['globalCaptureEmergency','globalClearEmergency','globalKeyEmergency'])
    assert(ids.includes(id),'Missing configurable emergency key in global settings: '+id);
assert(settings.includes('Arrêt d\'urgence') && settings.includes('F12 par défaut'),
    'Emergency key must be described alongside optional global shortcuts');
assert(html.includes("send('globalHotkey','clear','emergency')"),
    'Aucun must disable the actual emergency shortcut, not a second hotkey');
assert(html.includes("model.emergencyKey=msg.emergencyKey??'F12'"),
    'The WebView must preserve an explicitly blank emergency key from backend');
assert(html.includes("model.emergencyKey||'Aucun'"),
    'Emergency key labels must show Aucun when no key is assigned');

assert(html.includes("send('globalHotkey','clear',action)"),
    'Clear action must send explicit unassignment to AutoHotkey');
assert(html.includes("send('globalHotkey','begin',action)"),
    'Optional shortcut capture must connect to AutoHotkey WebView mode');
assert(html.includes("send('globalHotkey','set',action,picked)"),
    'Keyboard presses must be submitted to the native backend');
assert(html.includes("send('globalHotkey','cancel')"),
    'Escape must cancel capture natively');
assert(html.includes("msg.globalHotkeys"),'State synchronization for global keys is required');
for(const name of ['backupExport','backupRestore','overlaySize']){
    assert(ids.includes(name),'Missing new setting '+name);
}
for(const opt of ['mini','standard','large'])
    assert(settings.includes('value="'+opt+'"'), 'Missing overlay size '+opt);
assert(settings.includes('data-preference="overlayShowProfile"'),
    'Optional overlay profile name must be available');
assert(html.includes("send('backup','export')")&&html.includes("send('backup','restore')"),
    'Backup and restore must use native backend actions');
assert(html.includes("msg.type==='navigate'"),'Global hotkey Test CPS navigation must be handled');
console.log('v1.9 Settings groups, optional/unassigned global shortcuts, backups and overlay UI passed.');
