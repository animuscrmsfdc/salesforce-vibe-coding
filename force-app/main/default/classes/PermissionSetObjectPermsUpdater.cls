public with sharing class PermissionSetObjectPermsUpdater {
    // =========================
    // Configuration
    // =========================

    // Strategy flags
    private static final Boolean USE_ALLOW_LIST_ONLY    = true;   // safest: curated standards + custom objects
    private static final Boolean INCLUDE_CUSTOM_OBJECTS = true;   // include custom objects (excluding settings/metadata/__e)

    // Curated standard objects commonly permissionable (extend for your org)
    private static final Set<String> STANDARD_ALLOW_LIST = new Set<String>{
        'Account','Contact','Opportunity','Lead','Case',
        'Campaign','Asset','Contract','Order','OrderItem',
        'Product2','Pricebook2','PricebookEntry',
        'Quote','QuoteLineItem',
        'Entitlement','ServiceAppointment','WorkOrder','WorkOrderLineItem'
    };

    public class UpsertResultSummary {
        public Integer updatedCount = 0;
        public Integer insertedCount = 0;
        public Integer skippedCount  = 0;
        public Integer errorCount    = 0;
        public List<String> skippedObjects = new List<String>();
        public List<Database.Error> errors = new List<Database.Error>();
    }

    public static UpsertResultSummary upsertObjectPermissionsForPermSet(String permissionSetName) {
        UpsertResultSummary summary = new UpsertResultSummary();

        // --- Desired policy (centralized) -----------------------------------
        final Boolean allowCreate     = true;
        final Boolean allowRead       = true;
        final Boolean allowEdit       = true;
        final Boolean allowDelete     = false;
        final Boolean allowModifyAll  = false;
        final Boolean viewAllFields   = true;

        // --- Resolve Permission Set ----------------------------------------
        PermissionSet ps = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :permissionSetName
            LIMIT 1
        ];

        // --- Build permissionable object set --------------------------------
        Set<String> permissionableObjects = buildPermissionableObjectSet(summary);

        // --- Existing ObjectPermissions for the given PS --------------------
        List<ObjectPermissions> existingOps = [
            SELECT Id,
                   ParentId,
                   SObjectType,
                   PermissionsCreate,
                   PermissionsRead,
                   PermissionsEdit,
                   PermissionsDelete,
                   PermissionsModifyAllRecords,
                   PermissionsViewAllFields
            FROM ObjectPermissions
            WHERE ParentId = :ps.Id
        ];

        Set<String> existingObjNames = new Set<String>();
        for (ObjectPermissions op : existingOps) {
            existingObjNames.add(op.SObjectType);
        }

        // --- Delta: permissionable minus existing ---------------------------
        Set<String> missingObjNames = permissionableObjects.clone();
        missingObjNames.removeAll(existingObjNames);

        // --- Update existing rows (guarded) ---------------------------------
        for (ObjectPermissions op : existingOps) {
            if (permissionableObjects.contains(op.SObjectType)) {
                op.PermissionsCreate           = allowCreate;
                op.PermissionsRead             = allowRead;
                op.PermissionsEdit             = allowEdit;
                op.PermissionsDelete           = allowDelete;
                op.PermissionsModifyAllRecords = allowModifyAll;
                op.PermissionsViewAllFields    = viewAllFields;
            } else {
                summary.skippedCount++;
                summary.skippedObjects.add(op.SObjectType);
            }
        }

        // --- Create new rows for missing permissionable objects -------------
        List<ObjectPermissions> newOps = new List<ObjectPermissions>();
        for (String apiName : missingObjNames) {
            newOps.add(new ObjectPermissions(
                ParentId                    = ps.Id,
                SObjectType                 = apiName,
                PermissionsCreate           = allowCreate,
                PermissionsRead             = allowRead,
                PermissionsEdit             = allowEdit,
                PermissionsDelete           = allowDelete,
                PermissionsModifyAllRecords = allowModifyAll,
                PermissionsViewAllFields    = viewAllFields
            ));
        }

        // --- Upsert (update existing; insert new) ---------------------------
        List<ObjectPermissions> allToUpsert = new List<ObjectPermissions>();
        allToUpsert.addAll(existingOps);
        allToUpsert.addAll(newOps);
        allToUpsert.sort(); // optional

        // Use partial success to collect per-row errors instead of throwing
        Database.UpsertResult[] results = Database.upsert(allToUpsert, false);

        // --- Summary --------------------------------------------------------
        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult r = results[i];

            if (r.isSuccess()) {
                if (r.isCreated()) summary.insertedCount++;
                else summary.updatedCount++;
            } else {
                summary.errorCount += r.getErrors().size();
                summary.errors.addAll(r.getErrors());
            }
        }

        return summary;
    }

    // =========================
    // Helpers
    // =========================

    /**
     * Build a set of SObject API names that are safe for ObjectPermissions.
     * Layers:
     *  1) Describe-based exclusions (families & helpers, + __e Platform Events)
     *  2) Allow-list mode (curated standards + optionally custom objects)
     *  3) Union with known-permissible SObjectTypes already present anywhere in ObjectPermissions
     */
    private static Set<String> buildPermissionableObjectSet(UpsertResultSummary summary) {
        Set<String> result = new Set<String>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        // 1) Describe + exclusions
        Set<String> eligibleByDescribe = new Set<String>();
        for (String name : gd.keySet()) {
            Schema.DescribeSObjectResult d = gd.get(name).getDescribe();
            if (isEligibleByDescribe(d)) {
                eligibleByDescribe.add(d.getName());
            } else {
                summary.skippedCount++;
                summary.skippedObjects.add(d.getName());
            }
        }

        // 2) Apply allow-list strategy
        if (USE_ALLOW_LIST_ONLY) {
            // Curated standards
            result.addAll(STANDARD_ALLOW_LIST);

            // Custom objects (optional) — exclude __mdt / settings / __e via isEligibleByDescribe
            if (INCLUDE_CUSTOM_OBJECTS) {
                for (String n : eligibleByDescribe) {
                    Schema.DescribeSObjectResult d = gd.get(n).getDescribe();
                    if (d.isCustom()) {
                        result.add(n);
                    }
                }
            }
        } else {
            // Broader mode: use the eligible set from describe directly
            result.addAll(eligibleByDescribe);
        }

        // 3) Union with SObjectTypes that already exist in ObjectPermissions anywhere in the org
        //    This adds valid standards beyond our curated list, but only those Salesforce actually permits.
        for (ObjectPermissions op : [SELECT SObjectType FROM ObjectPermissions]) {
            result.add(op.SObjectType);
        }

        return result;
    }

    /**
     * Conservative eligibility: exclude families that never take ObjectPermissions,
     * helper/metadata types, Platform Events (__e), and require accessibility & queryability.
     */
    private static Boolean isEligibleByDescribe(Schema.DescribeSObjectResult d) {
        String n  = d.getName();
        String nl = n.toLowerCase();

        // Custom Settings & Custom Metadata
        if (d.isCustomSetting()) return false;
        if (nl.endsWith('__mdt')) return false;   // Custom Metadata Types

        // Platform Events
        if (nl.endsWith('__e')) return false;     // ⬅️ exclude all Platform Events

        // Optional: Big Objects
        // if (nl.endsWith('__b')) return false;   // uncomment if you want to exclude Big Objects too

        // Deprecated/Hidden objects
        if (d.isDeprecatedAndHidden()) return false;

        // Families to exclude (both standard and custom)
        if (nl.endsWith('share')       || nl.endsWith('__share'))     return false;
        if (nl.endsWith('history')     || nl.endsWith('__history'))   return false;
        if (nl.endsWith('feed'))                                       return false;
        if (nl.endsWith('changeevent'))                                return false;
        if (nl.endsWith('relation'))                                   return false;
        if (nl.endsWith('role'))                                       return false; // e.g., AccountContactRole

        // Common helper/infra objects (never permissioned)
        Set<String> helpers = new Set<String>{
            'userrecordaccess', 'recordtype', 'recentlyviewed',
            'listview', 'name', 'activityhistory', 'openactivity',
            'duplicaterecorditem', 'duplicaterecordset'
        };
        if (helpers.contains(nl)) return false;

        // Basic sanity: must be accessible & queryable
        if (!d.isAccessible()) return false;
        if (!d.isQueryable())  return false;

        return true;
    }
}