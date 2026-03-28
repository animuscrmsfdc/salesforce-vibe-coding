@isTest
public class FitnessTest {
	@isTest
    public static void calculateBMIPositiveTest(){
        Decimal bodyWeightKgs = 60;
        Decimal bodyHeightsMts = 1.2;
        
        Decimal result = Fitness.calculateBMI(bodyWeightKgs, bodyHeightsMts);        
        System.assertEquals(41.67, result, 'Error: different BMI calculated');
    }
    @isTest
    public static void calculateBMINegativeTest(){
        Decimal bodyWeightKgs = -60;
        Decimal bodyHeightsMts = 1.2;
        
        Decimal result = Fitness.calculateBMI(bodyWeightKgs, bodyHeightsMts);        
        System.assertEquals(-1, result, 'Error: result should be -1 because negative numbers');
    }
    
    // TODO : BMI - more scenarios with positive and negative decimal numbers

	@isTest
    public static void calculatePacePositiveTest(){
        Decimal distanceKms = 10;
        Decimal minutes = 60;
        
        Decimal result = Fitness.calculatePace(distanceKms, minutes);        
        System.assertEquals(1, result, 'Error: different Pace calculated');
	}
    @isTest
    public static void calculatePaceNegativeTest(){
        Decimal distanceKms = -10;
        Decimal minutes = 60;
        
        Decimal result = Fitness.calculatePace(distanceKms, minutes);        
        System.assertEquals(-1, result, 'Error: result should be -1 because negative numbers');
	}
    // TODO : Pace - more scenarios with positive and negative decimal numbers
  
}