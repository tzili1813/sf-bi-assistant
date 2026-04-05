/**
 * BIQueryValidator
 * ----------------
 * Security guardrails executed BEFORE any LLM-generated SOQL runs.
 * Throws AuraHandledException on any violation.
 *
 * Rules:
 *   1. Must be a SELECT statement (no DML).
 *   2. Must contain a LIMIT clause.
 *   3. LIMIT value <= MAX_LIMIT.
 *   4. All FROM targets must be in the allowed set.
 *   5. No SQL-injection patterns (comments, semicolons, UNION).
 */
public with sharing class BIQueryValidator {

    private static final Integer MAX_LIMIT = 200;

    // Keep in sync with BISchemaService.OBJECTS_TO_DESCRIBE
    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'account', 'contact', 'opportunity', 'lead',
        'case', 'task', 'event',
        // ── Service Cloud ──
        'casecomment', 'casehistory', 'entitlement',
        'servicecontract', 'workorder', 'workorderlineitem',
        'asset', 'livechattranscript', 'messagingsession'
    };

    private static final List<String> BLOCKED_KEYWORDS = new List<String>{
        'insert', 'update', 'delete', 'upsert', 'merge',
        'undelete', 'grant', 'revoke'
    };

    public static void validate(String soql) {
        if (String.isBlank(soql)) {
            throw buildException('Empty query received from AI.');
        }

        String n = soql.trim().toLowerCase();

        if (!n.startsWith('select ')) {
            throw buildException(
                'Only SELECT queries are allowed. The AI generated an invalid statement.'
            );
        }

        for (String kw : BLOCKED_KEYWORDS) {
            if (n.contains(kw + ' ') || n.endsWith(kw)) {
                throw buildException(
                    'Query contains a blocked keyword: ' + kw.toUpperCase()
                );
            }
        }

        if (!n.contains(' limit ')) {
            throw buildException(
                'Query must include a LIMIT clause for safety.'
            );
        }

        Integer limitValue = extractLimit(n);
        if (limitValue != null && limitValue > MAX_LIMIT) {
            throw buildException(
                'Query LIMIT (' + limitValue + ') exceeds the maximum (' + MAX_LIMIT + ').'
            );
        }

        List<String> objectNames = extractAllObjectNames(n);
        for (String objectName : objectNames) {
            if (!ALLOWED_OBJECTS.contains(objectName.toLowerCase())) {
                throw buildException(
                    'Querying "' + objectName + '" is not permitted. '
                    + 'Allowed: ' + String.join(new List<String>(ALLOWED_OBJECTS), ', ')
                );
            }
        }

        if (n.contains('--') || n.contains('/*') || n.contains('*/')) {
            throw buildException(
                'Query contains comment characters which are not allowed.'
            );
        }

        if (n.contains(';')) {
            throw buildException(
                'Query contains semicolons which are not allowed.'
            );
        }

        if (n.contains('union ')) {
            throw buildException(
                'Query contains UNION which is not allowed.'
            );
        }
    }

    private static AuraHandledException buildException(String msg) {
        AuraHandledException e = new AuraHandledException(msg);
        e.setMessage(msg);
        return e;
    }

    private static Integer extractLimit(String n) {
        Integer idx = n.lastIndexOf(' limit ');
        if (idx < 0) return null;
        String after = n.substring(idx + 7).trim();
        String digits = '';
        for (Integer i = 0; i < after.length(); i++) {
            String ch = after.substring(i, i + 1);
            if (ch >= '0' && ch <= '9') {
                digits += ch;
            } else {
                break;
            }
        }
        return String.isNotBlank(digits) ? Integer.valueOf(digits) : null;
    }

    private static List<String> extractAllObjectNames(String n) {
        List<String> objects = new List<String>();
        Integer searchFrom = 0;
        while (true) {
            Integer idx = n.indexOf(' from ', searchFrom);
            if (idx < 0) break;
            String after = n.substring(idx + 6).trim();
            String objName = after.split('\\s+')[0].replaceAll('[^a-zA-Z0-9_]', '');
            if (String.isNotBlank(objName)) {
                objects.add(objName);
            }
            searchFrom = idx + 6;
        }
        return objects;
    }
}
