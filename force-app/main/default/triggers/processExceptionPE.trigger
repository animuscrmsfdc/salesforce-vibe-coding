trigger processExceptionPE on Exception_Log__e (after insert) {
    List<Exception__c> ecelist = New List<Exception__c>();
    for(Exception_Log__e ex : Trigger.new) {
        Exception__c excep = new Exception__c();
        excep.Object__c = ex.Object__c;
        excep.Operation__c = ex.Operation__c;
        excep.Record_Id__c = ex.Record_Id__c;
        excep.Exception_Details__c = ex.Exception_Details__c;
        ecelist.add(excep);
    }
    if (ecelist.size()>0){
        insert ecelist;
    }

}