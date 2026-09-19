global class VehicleOrderBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Status__c, Vehicle__c
            FROM Vehicle_Order__c
            WHERE Status__c = 'Pending'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Vehicle_Order__c> orderList) {

        Set<Id> vehicleIds = new Set<Id>();

        // Collect vehicle IDs from pending orders
        for (Vehicle_Order__c order : orderList) {

            if (order.Vehicle__c != null) {
                vehicleIds.add(order.Vehicle__c);
            }
        }

        if (!vehicleIds.isEmpty()) {

            // Get vehicle stock information
            Map<Id, Vehicle__c> vehicleStockMap =
                new Map<Id, Vehicle__c>();

            for (Vehicle__c vehicle : [
                SELECT Id, Stock_Quantity__c
                FROM Vehicle__c
                WHERE Id IN :vehicleIds
            ]) {

                vehicleStockMap.put(vehicle.Id, vehicle);
            }

            List<Vehicle_Order__c> ordersToUpdate =
                new List<Vehicle_Order__c>();

            List<Vehicle__c> vehiclesToUpdate =
                new List<Vehicle__c>();

            // Process pending orders
            for (Vehicle_Order__c order : orderList) {

                if (vehicleStockMap.containsKey(order.Vehicle__c)) {

                    Vehicle__c vehicle =
                        vehicleStockMap.get(order.Vehicle__c);

                    if (vehicle.Stock_Quantity__c > 0) {

                        // Confirm the order
                        order.Status__c = 'Confirmed';

                        // Reduce vehicle stock
                        vehicle.Stock_Quantity__c -= 1;

                        ordersToUpdate.add(order);
                        vehiclesToUpdate.add(vehicle);
                    }
                }
            }

            // Update orders
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }

            // Update vehicle stock
            if (!vehiclesToUpdate.isEmpty()) {
                update vehiclesToUpdate;
            }
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug('Vehicle order batch job completed.');
    }
}
