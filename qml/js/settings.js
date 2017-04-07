.pragma library
.import QtQuick.LocalStorage 2.0 as LS

.import "./storage.js" as Storage

var db = Storage.db;

/**
 * Read all settings.
 */
function readAll() {
    var res = {};
    db.readTransaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM settings;')
        for (var i=0; i<rs.rows.length; i++) {
            if (rs.rows.item(i).value === 'true') {
                res[rs.rows.item(i).key] = 1;
            }
            else if (rs.rows.item(i).value === 'false') {
                res[rs.rows.item(i).key] = 0;
            } else {
                res[rs.rows.item(i).key] = rs.rows.item(i).value
            }
            //console.log("key=" + rs.rows.item(i).key + "; value=" + rs.rows.item(i).value);
        }
    });
    return res;
}

/**
 * Write setting to database.
 */
function write(key, value) {
    //console.log("writeSetting(" + key + "=" + value + ")");

    if (value === true) {
        value = 'true';
    }
    else if (value === false) {
        value = 'false';
    }

    db.transaction(function(tx) {
        tx.executeSql("INSERT OR REPLACE INTO settings VALUES (?, ?);", [key, value]);
        tx.executeSql("COMMIT;");
    });

}

/**
 * Read given setting from database.
 */
function read(key) {
    var res = "";
    db.readTransaction(function(tx) {
        var rows = tx.executeSql("SELECT value AS val FROM settings WHERE key=?;", [key]);

        if (rows.rows.length !== 1) {
            res = "";
        } else {
            res = rows.rows.item(0).val;
        }
    });

    if (res === 'true') {
        return true;
    }
    else if (res === 'false') {
        return false;
    }

    //console.log("readSetting(" + key + ")", res);
    console.log("db verseion:", db.version);


    return res;
}

