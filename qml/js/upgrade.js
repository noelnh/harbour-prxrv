.pragma library

.import "./storage.js" as Storage
.import "./accounts.js" as Accounts
.import "./settings.js" as Settings

var version = "1.1";


var db = Storage.db;

/**
 * Upgrade database
 */
function upgrade() {

    if (version !== db.version) {
        console.warn("Version mismatch:", db.version, version);
        if (db.version == "1.0" && version == "1.1") {
            console.log("Upgrading database...");
            try {
                db.changeVersion(db.version, version, function(tx) {
                    tx.executeSql("DROP TABLE IF EXISTS accounts;");
                    tx.executeSql(Storage.QUERY.CREATE_ACCOUNTS_TABLE);
                });

                // Import user info to table "accounts"
                var data = {};
                var settings = Settings.readAll();
                if (settings.user && settings.passwd) {
                    settings.password = settings.passwd;
                    settings.isActive = 1;
                    settings.remember = 1;
                    Accounts.save(JSON.parse(settings.user), settings);
                    console.log("Transform done:", JSON.stringify(settings));
                }
                console.log("Upgrade done");
            } catch (err) {
                console.error("Exception:", err);
            }
        } else {
            console.log("Unable to upgrade database!");
        }
    }

    return db.version
}

function downgrade() {
    if (version !== db.version) {
        console.warn("Version mismatch:", db.version, version);
        if (db.version == "1.1" && version == "1.0") {
            console.log("Downgrading database...");
            db.changeVersion(db.version, version, function(tx) {
                tx.executeSql("DROP TABLE IF EXISTS accounts;");
            });
            console.log("Downgrade done");
        } else {
            console.warn("Unable to downgrade database!");
        }
    }
}

function reset() {
    Storage.reset();
}
