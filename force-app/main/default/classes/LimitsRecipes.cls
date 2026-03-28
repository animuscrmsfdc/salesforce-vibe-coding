/**
 * @description Demonstrates how limits work 
 * 
 */

public with sharing class LimitsRecipes {

    public static void getQueries() {
        system.debug('#### get queries: '+ Limits.getQueries());
        system.debug('$$$$ get Limit queries: '+ Limits.getLimitQueries());      


    }

public static void checkLimitsAndDetermineExecutionPath(){

    for (Integer i = 0; i < 100; i++) {
        List <Account> accts =[SELECT ID from Account LIMIT 1];

    }
}
 }