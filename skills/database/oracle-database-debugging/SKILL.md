---
name: oracle-database-debugging
description: "Diagnose Oracle DB errors from stack traces."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [oracle, database, debugging, sql, diagnostics]
    related_skills: [systematic-debugging]
---

# Oracle Database Debugging

## When to Use

Use for ANY Oracle database error from application logs, stack traces, or user reports:
- ORA-00904, ORA-00942, ORA-01017, ORA-12154, ORA-12514
- Connection failures with Oracle.ManagedDataAccess or System.Data.OracleClient
- Production bugs in deployed .NET/Java/Python apps using Oracle
- Schema-drift issues after database migrations

**Use this ESPECIALLY when:**
- Stack trace points to a compiled binary and source is unavailable
- DBA asks what column/table the app is actually querying
- Error text is clear but the exact SQL is hidden in a framework or dynamically built

## Core Principle

Oracle error codes are specific. Match the exact ORA-XXXXX code first; do not pattern-match symptom text. Each code has one root-cause family and one verification query.

## Always-On Rules

1. **Extract the exact ORA-XXXXX code from the error text.** Do not stop at the message string.
2. **Read the full stack trace to the first application frame above Oracle.ManagedDataAccess.** That is where the bad SQL or bad connection call originates.
3. **Verify against the database before proposing fixes.** Schema drift (renamed columns, new schemas) is the #1 cause of ORA-00904.
4. **Check for quoted identifiers before renaming anything.** Columns created with `"MixedCase"` require exact-case double-quoted references.
5. **If source is unavailable, obtain it.** Binary string extraction almost never yields dynamically constructed SQL; the developer must supply the query text.
6. **Never alter production data or schema during diagnosis.** Verification queries only.

## Decision Flow

### ORA-00904: invalid identifier

**Meaning:** The column or expression name in the SELECT/WHERE/ORDER BY does not exist in the referenced table or view, or it is misspelled, or it requires a table alias, or it is a quoted identifier with mismatched case.

**Diagnostic query:**
```sql
SELECT owner, table_name, column_name, data_type, data_default
FROM all_tab_columns
WHERE table_name = 'TARGET_TABLE'
  AND owner = 'TARGET_SCHEMA'
ORDER BY column_id;
```

**Common causes in order:**
- Column name typo or rename (`CLIENT` vs `CLIENT_ID` / `CLIENT_CODE` / `CLIENT_NAME`).
- Missing table alias in a multi-table join.
- Quoted identifier case mismatch (column created as `"Client"`, queried as `CLIENT`).
- Column exists in another schema; needs `SCHEMA.TABLE.COLUMN`.

**Fix:** Update the query to match the verified column name. Prefer unquoted, uppercase identifiers.

### ORA-00942: table or view does not exist

**Meaning:** The table/view name is wrong, missing, or the user lacks CREATE SELECT privilege.

**Diagnostic query:**
```sql
SELECT owner, object_name, object_type, status
FROM all_objects
WHERE object_name = 'TARGET_TABLE';
```

**Fix:** Correct table name, add schema prefix, or grant `SELECT` on the table to the app user.

### ORA-01017: invalid username/password; logon denied

**Meaning:** Credentials are wrong, or the account is locked/expired.

**Diagnostic query (DBA only):**
```sql
SELECT username, account_status, lock_date, expiry_date
FROM dba_users
WHERE username = 'APP_USER';
```

**Fix:** Reset password, unlock account, or update connection string. Check for case-sensitive password mismatch.

### ORA-12154: TNS:could not resolve the connect identifier specified

**Meaning:** The service name in the connection string is not defined in tnsnames.ora, or the TNS_ADMIN path is wrong.

**Fix:** Verify `tnsnames.ora` contains the exact service name; set `TNS_ADMIN` to the folder containing it, or use EZCONNECT (`host:port/service`).

### ORA-12514: TNS:listener does not currently know of service requested in connect descriptor

**Meaning:** The service exists in tnsnames.ora but the listener does not have it registered (wrong service name, wrong port, database down).

**Fix:** Verify service name on the DB server (`lsnrctl status`); confirm host and port in the connection string.

## Handling Missing Source Code

When the failing app is deployed as a compiled binary (EXE/DLL) and source is unavailable:

1. **Extract the method name from the stack trace** (e.g. `CLIENT1_Multi.MQTT_Init` at line 928). This identifies the component but not the SQL.
2. **Attempt binary string extraction** only to confirm assembly names and method paths; do not expect to recover exact SQL, which is often built dynamically.
3. **Pivot to the developer or source repository.** The only reliable fix is the developer updating the query to match the current schema.
4. **Provide the DBA the diagnostic queries above** so they can confirm the correct column/table names without guessing.

## Output Contract

When reporting findings, give the user:
- The exact ORA code and its meaning.
- The verification query they can run in SQL*Plus / SQL Developer.
- The ranked causes specific to that code.
- The single-line SQL fix or the request for source access, as appropriate.

Do not list every possible Oracle error. Stick to the code found in the user's stack trace.
