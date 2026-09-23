const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {test} = require('node:test');
const vm = require('node:vm');

test('loading screen does not collide with Flutter debug loader globals', () => {
  const source = fs.readFileSync(
    path.join(__dirname, '../web/flutter_bootstrap.js'),
    'utf8',
  ).replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
  let started = false;
  const context = vm.createContext({
    document: {getElementById: () => null},
    window: {setTimeout: () => 1},
    _flutter: {loader: {load: () => { started = true; }}},
  });

  vm.runInContext(source, context);
  // Flutter's debug entrypoint shares the classic-script global scope.
  assert.doesNotThrow(() => vm.runInContext('const loader = {};', context));
  assert.equal(started, true);
});
