.pragma library
.import QtQuick.LocalStorage 2.0 as LS


var identifier = "harbour-prxrv";
var description = "Prxrv Database";

var QUERY = {
    CREATE_SETTINGS_TABLE: 'CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT);',
    CREATE_ACCOUNTS_TABLE: 'CREATE TABLE IF NOT EXISTS accounts(id TEXT PRIMARY KEY, account TEXT, name TEXT, password TEXT, user TEXT, token TEXT, refreshToken TEXT, expireOn TEXT, remember INTEGER, isActive INTEGER);'
}

/**
 * Open app's database, create it if not exists.
 */
var db = LS.LocalStorage.openDatabaseSync(identifier, "", description, 1000000, function(db) {
    db.changeVersion(db.version, "1.0", function(tx) {
        // Create tables
        tx.executeSql(QUERY.CREATE_SETTINGS_TABLE);
        tx.executeSql(QUERY.CREATE_ACCOUNTS_TABLE);
    });
});

/**
 * Reset
 */
function reset() {
    db.transaction(function(tx) {
        tx.executeSql("DROP TABLE IF EXISTS settings;");
        tx.executeSql("DROP TABLE IF EXISTS accounts;");
        tx.executeSql(QUERY.CREATE_SETTINGS_TABLE);
        tx.executeSql(QUERY.CREATE_ACCOUNTS_TABLE);
        tx.executeSql("COMMIT;");
    });
}

/**
 * Read
 */
function read(table, key, value) {
    var results;
    db.transaction(function(tx){
        results = tx.executeSql("SELECT * FROM ? WHERE ? = ?;", [table, key, value]);
    });
    return results.rows || [];
}
