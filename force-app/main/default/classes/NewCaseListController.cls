public class NewCaseListController {
    public List<case> getNewCases()
    {    
     list<case>newcase =[select id,casenumber from case where status='New'];
     return newcase;
    }
}