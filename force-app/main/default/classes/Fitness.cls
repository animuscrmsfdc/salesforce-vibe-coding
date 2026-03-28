public class Fitness{
    public static Decimal calculateBMI(Decimal bodyWeightKgs, Decimal bodyHeightMts){
        if(bodyHeightMts <= 0 || bodyWeightKgs <0){
            return -1;
        }
        Decimal bmi = bodyWeightKgs / (bodyHeightMts*bodyHeightMts);
        bmi = bmi.setScale(2, RoundingMode.HALF_UP);
        return bmi;
    }
    public static Decimal calculatePace(Decimal distanceKms, Decimal minutes){
        if (distanceKms < 0 || minutes <=0){
            return -1;
        }
        Decimal hr = minutes / 60;
        Decimal paceKmsHour = distanceKms / hr;
        paceKmsHour = paceKmsHour.setScale(2, RoundingMode.HALF_UP);
        return paceKmsHour;
    }
    
}