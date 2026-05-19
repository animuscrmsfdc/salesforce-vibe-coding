/**
 * BearController
 *
 * Author:         David Sanchez
 * Created:        2026-05-15
 * Last Modified:  2026-05-15 by David Sanchez
 * Change Ref:     <unspecified>
 * SOX Scope:      Out-of-Scope   // tutorial/demo controller, no financial-data path
 *
 * Purpose:
 *   Aura-enabled controller exposing read-only Bear__c data to LWC/Aura
 *   components. Provides a default list of bears (getAllBears) and a
 *   name-based search (searchBears) for demo/tutorial UI consumption.
 *
 * Identified Risks:
 *   Security:
 *     - No FLS enforcement on either query (getAllBears lines 42-56,
 *       searchBears lines 69-84). Both traverse Supervisor__r.Name, so
 *       WITH SECURITY_ENFORCED is unsafe per project standards; results
 *       should be filtered via
 *       Security.stripInaccessible(AccessType.READABLE, results).getRecords().
 *     - searchTerm is bound via :searchTerm (no SOQL injection) but is
 *       not sanitised for SOQL LIKE wildcards (% and _) before being
 *       wrapped at line 67, allowing callers to widen matches beyond intent.
 *   Performance:
 *     - searchBears uses a leading-wildcard LIKE ('%term%', line 67) which
 *       prevents index usage on Name and forces a full scan; cost grows
 *       linearly with Bear__c volume.
 *     - Hard-coded LIMIT 50 (lines 55, 83) with no pagination/offset
 *       support; truncates silently beyond 50 matches.
 *   Functional:
 *     - searchTerm.trim() at line 62 throws NullPointerException if the
 *       caller passes null; no guard precedes it.
 *     - No try/catch; raw exceptions surface to the LWC client without
 *       an AuraHandledException wrapper, leaking stack traces.
 *
 * Tags: Apex, Controller, AuraEnabled, LWC, SOQL, Cacheable, Search,
 *       Bear__c, FLS, with-sharing
 */
public with sharing class BearController {
    @AuraEnabled(Cacheable=true)
    public static Bear__c[] getAllBears() {
        return [
            SELECT
                Id,
                Name,
                Age__c,
                Sex__c,
                Height__c,
                Weight__c,
                Location__Latitude__s,
                Location__Longitude__s,
                Supervisor__r.Name
            FROM Bear__c
            ORDER BY Name
            LIMIT 50
        ];
    }

    @AuraEnabled(Cacheable=true)
    public static Bear__c[] searchBears(String searchTerm) {
        // Return all bears when no search term
        searchTerm = searchTerm.trim();
        if (searchTerm == '') {
            return getAllBears();
        }
        // Prepare query paramters
        searchTerm = '%' + searchTerm + '%';
        // Execute search query
        return [
            SELECT
                Id,
                Name,
                Age__c,
                Sex__c,
                Height__c,
                Weight__c,
                Location__Latitude__s,
                Location__Longitude__s,
                Supervisor__r.Name
            FROM Bear__c
            WHERE Name LIKE :searchTerm
            ORDER BY Name
            LIMIT 50
        ];
    }
}