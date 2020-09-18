global class TotalAmountSchedule implements Schedulable {
    public static String CRON_EXP = '0 0 20 ? * FRI *';
    global void execute(SchedulableContext ctx) {
        // awesome code here
        TotalAmountBatch totalAmountBatch = new TotalAmountBatch();
        Database.executeBatch(totalAmountBatch);
    }
}
