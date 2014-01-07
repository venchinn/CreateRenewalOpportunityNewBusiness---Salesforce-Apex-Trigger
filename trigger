trigger CreateRenewalOpportunityNewBusiness on Opportunity (after update, after insert) {
    List<Id> opps = new List<Id>();
    
    for( Opportunity opp : Trigger.new ) {
        if( ( opp.RecordTypeId != '01240000000UP7y' ) &&
            ( opp.RecordTypeId != '01240000000UP8D' ) &&
            ( opp.RecordTypeId != '01240000000URXp' ) ) {
            continue;
        }
        
        if( ( opp.StageName != '07-Close/Won' ) ||
            ( Trigger.isUpdate && (Trigger.oldMap.get(opp.Id).StageName == opp.StageName ) ) ) {
            continue;
        }
        
        opps.add( opp.Id );
    }
    
    List<zqu__Quote__c> quotes = [SELECT zqu__StartDate__c, zqu__InitialTerm__c, zqu__RenewalTerm__c, zqu__Opportunity__c 
        from zqu__Quote__c where zqu__Opportunity__c IN : opps order by LastModifiedDate desc];
    
    Map<Id, zqu__Quote__c> quotesMap = new Map<Id, zqu__Quote__c>();
    for( zqu__Quote__c quote: quotes ) {
        if( quotesMap.get( quote.zqu__Opportunity__c ) != null ) {
            continue;
        }
        
        quotesMap.put( quote.zqu__Opportunity__c, quote );
    }
    
    Map<Id,Opportunity> oppsMap = new Map<Id,Opportunity>( [SELECT Id, AccountId, Account.Name, RecordTypeId from Opportunity where Id IN :opps] );
    
    List<Opportunity> renewalOpps = new List<Opportunity>();
    
    for( Opportunity opp : oppsMap.values() ) {
        Opportunity renewalOpp = new Opportunity();
        
        Date renewalDate = Date.today();
        Date closeDate = Date.today();
        
        zqu__Quote__c quote = quotesMap.get( opp.Id );
        if( ( quote != null ) &&
            ( quote.zqu__StartDate__c != null ) &&
            ( quote.zqu__InitialTerm__c != null )  ) {
            Integer term = Integer.valueOf( quote.zqu__InitialTerm__c );
            renewalDate = quote.zqu__StartDate__c.addMonths(term).addDays(1);
            closeDate = renewalDate;
        } else if( ( opp.RecordTypeId == '01240000000UP83' ) &&
          ( quote != null ) &&
            ( quote.zqu__StartDate__c != null ) &&
            ( quote.zqu__RenewalTerm__c != null ) ) {
          Integer term = Integer.valueOf( quote.zqu__RenewalTerm__c );
            renewalDate = quote.zqu__StartDate__c.addMonths(term).addDays(1);
            closeDate = renewalDate;
        }
        
        String renewalDateString = '' + renewalDate;
        renewalDateString = renewalDateString.substring(0, renewalDateString.indexOf(' '));
        
        renewalOpp.CloseDate = closeDate + 365;
        renewalOpp.Expiration_Date__c = closeDate + 365;
        renewalOpp.OwnerId = '00540000001w25Q';
        renewalOpp.RecordTypeId = '01240000000UP83';
        renewalOpp.AccountId = opp.AccountId;
        renewalOpp.Next_Steps__c = 'Review Account Status, send renewal notice and quote.';
        renewalOpp.Amount = 1000;
        renewalOpp.Original_Amount__c = 555;
        renewalOpp.Original_Opportunity__c = opp.Id;
        renewalOpp.StageName = '00-Not Contacted for Renewal';
        renewalOpp.Name = opp.Account.Name + ' Renewal ' + renewalOpp.Expiration_Date__c;
        
        renewalOpps.add(renewalOpp);
    }
    
    insert renewalOpps;
}
