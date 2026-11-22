const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');
const version = read('VERSION').trim();
assert.match(version, /^\d+\.\d+\.\d+$/, 'VERSION must be semantic');

function includesAll(file, ...expected) {
    const contents = read(file);
    for (const phrase of expected) {
        assert(contents.includes(phrase),
            file + ' must contain ' + JSON.stringify(phrase));
    }
}

includesAll('src/ClickFlow-WebView2.ahk',
    'ClickFlow v' + version,
    'ClickFlow - AutoCliker v' + version);
includesAll('ui/index.html',
    'ClickFlow v' + version + ' · AHK v2',
    'ClickFlow v' + version + ' · AutoHotkey v2');
includesAll('tools/build_single_ahk.py',
    'VERSION = "' + version + '"',
    'Runtime-' + version,
    'ClickFlow-v' + version + '.ahk',
    'FileAppend("' + version + '", readyFlag');
includesAll('.github/workflows/windows.yml',
    'ClickFlow-v' + version + '.ahk',
    'ClickFlow-WebView2-v' + version + '-win-x64.zip',
    'Runtime-' + version);
includesAll('README.md',
    'Version stable ' + version,
    'ClickFlow-v' + version + '.ahk',
    'Runtime-' + version);
includesAll('docs/ARCHIVES.md',
    'releases/tag/v' + version);
includesAll('CHANGELOG.md', '## ' + version + ' - ');

// Personal storage must not move when the runtime version changes.
const backend = read('src/ClickFlow-Backend.ahk');
const launcher = read('tools/build_single_ahk.py');
includesAll('src/ClickFlow-Backend.ahk',
    'configFile: A_AppData "\\ClickFlow\\settings.ini"',
    'profilesDir: A_AppData "\\ClickFlow\\profiles"');
assert(
    launcher.includes('stableScript := appDir "\\ClickFlow.ahk"'),
    'Stable user launcher path must not be versioned'
);
assert(
    launcher.includes('runtimeDir := appDir "\\Runtime-'),
    'New version must get its own runtime directory'
);
assert(
    !backend.includes('settings-' + version + '.ini'),
    'Personal settings must not use version-specific filenames'
);

console.log('Release metadata, user storage paths and v' + version
    + ' consistency passed.');
