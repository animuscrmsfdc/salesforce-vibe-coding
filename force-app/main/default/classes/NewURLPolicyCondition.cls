global class NewURLPolicyCondition implements TxnSecurity.PolicyCondition {

 public boolean evaluate(TxnSecurity.Event e) {
LoginHistory eObj = [SELECT CountryIso FROM LoginHistory WHERE Id = :e.data.get('LoginHistoryId')];
  if(eObj.CountryIso == 'USA') {
   return true;
 }

 return false; 
}
 }