.pragma library

.import "./storage.js" as Storage

var db = Storage.db;

/**
 * Read setting
 */
function readSetting(name) {
    var value = null;
    var result = read('settings', 'key', name);
    if (result && result.length === 1) {
        value = result.item(0).val;
    }
    if (value === 'true') {
        value = true;
    }
    if (value === 'false') {
        value = false;
    }
    return value;
}


/**
 * Write setting
 */
function writeSetting(name, value) {
    if (value === true) {
        value = 'true';
    }
    if (value === false) {
        value = 'false';
    }
    write('settings', name, value);
}

