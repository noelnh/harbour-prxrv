.pragma library
.import QtQuick.LocalStorage 2.0 as LS

.import "./storage.js" as Storage

var db = Storage.db;

var columns = ["id", "account", "name", "password", "user", "token", "refreshToken", "expireOn", "remember"]

/**
 * Find all accounts
 */
function findAll(onSingle, callBefore, callAfter) {
    db.readTransaction(function(tx) {
        var results = tx.executeSql("SELECT * FROM accounts;");
        var len = results.rows.length;

        if (typeof callBefore === "function") {
            callBefore();
        }

        if (typeof onSingle === "function") {
            for (var i = 0; i < len; i++) {
                onSingle(results.rows.item(i));
            }
        }

        if (typeof callAfter === "function") {
            var accounts = [];
            for (var i = 0; i < len; i++) {
                accounts.push(results.rows.item(i));
            }
            callAfter(accounts);
        }

    });
}

/**
 * Find account by "id" or "account"
 */
function find(key, value) {
    var account = null;
    if (key !== 'id' && key !== 'account' && key !== 'isActive') {
        console.warn("Invalid key:", key);
        return;
    }
    db.readTransaction(function(tx) {
        var query = "SELECT * FROM accounts WHERE " + key + "=?;";
        var results = tx.executeSql(query, [value]);

        if (results.rows.length !== 1) {
            console.error("Found 0 or more than one account:", results.rows.length);
            account = null;
        } else {
            account = results.rows.item(0);
        }
    });
    return account;
}

/**
 * Get current account
 */
function current() {
    return find("isActive", 1);
}

/**
 * Change account
 */
function change(accountName) {
    var changed = false;
    db.transaction(function(tx) {
        tx.executeSql("UPDATE accounts SET isActive=0;");
        tx.executeSql("UPDATE accounts SET isActive=1 WHERE account=?;", [accountName]);
        tx.executeSql("COMMIT;");
        changed = true;
    });
    return changed;
}

/**
 * Remove an account
 */
function remove(accountName) {
    var result = false;
    db.transaction(function(tx) {
        try {
            tx.executeSql("DELETE FROM accounts WHERE account=?;", [accountName]);
            tx.executeSql("COMMIT;");
            result = true;
        } catch (err) {
            console.error("Error deleting from table accounts:", err);
            result = false;
        }
    });
    return result;
}

/**
 * Update an account
 */
function update(accountName, password, remember, isActive) {

    // Change active account first
    if (isActive) { change(accountName); }

    var result = false;
    db.transaction(function(tx) {
        try {
            tx.executeSql("UPDATE accounts SET password=?, remember=?, isActive=? WHERE account=?;",
                          [password, remember, isActive, accountName]);
            tx.executeSql("COMMIT;");
            result = true;
        } catch (err) {
            console.error("Error updating table accounts:", err);
            result = false;
        }
    });
    return result;
}


/**
 * Add or update an account
 */
function save(user, data, extraOptions) {
    var result = false;

    data.id = user.id;
    data.account = user.account;
    data.name = user.name;
    data.user = JSON.stringify(user);

    data.password = data.password || "";
    data.token = data.token || "";
    data.refreshToken = data.refreshToken || "";
    data.expireOn = data.expireOn || "";
    data.remember = data.remember || 1;
    data.isActive = data.isActive || 0;

    if (extraOptions) {
        data.password = extraOptions.password;
        data.remember = extraOptions.remember;
        data.isActive = extraOptions.isActive;
    }

    for (var i = 0; i < columns.length; i++) {
        var key = columns[i];
        if (!data.hasOwnProperty(key)) {
            return false;
        }
        if (data[key] === undefined) {
            console.error("Failed to save: " + key + " not found:");
            return false;
        }
    }

    db.transaction(function(tx) {
        try {
            if (!data.password) {
                var queryResults = tx.executeSql("SELECT password, remember, isActive FROM accounts WHERE account=?", [data.account]);
                var user = queryResults.rows.item(0);
                if (user) {
                    data.password = user.password;
                    data.remember = user.remember;
                    data.isActive = user.isActive;
                }
            }
            tx.executeSql("INSERT OR REPLACE INTO accounts VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                      [data.id, data.account, data.name, data.password, data.user,
                       data.token, data.refreshToken, data.expireOn, data.remember, data.isActive]);
            tx.executeSql("COMMIT;");
            result = true;
        } catch (err) {
            console.error("Error inserting or replacing into table accounts:" + err);
            result = false;
        }
    });

    // Change active account
    if (data.isActive) { change(data.account); }

    return result;
}
