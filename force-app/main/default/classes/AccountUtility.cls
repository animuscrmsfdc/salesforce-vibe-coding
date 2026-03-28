public class AccountUtility {
    public static void viewAnnualRevenue () {
        List < Account > accountsList = [SELECT Name, AnnualRevenue FROM Account];
        String acctRev; 
        For (Account a : accountsList) {
        	acctRev = a.Name + ' : ' + a.AnnualRevenue;
            system.debug(acctRev);
        }
    }
}