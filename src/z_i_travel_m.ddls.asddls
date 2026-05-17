@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel View - CDS Data Model'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_TRAVEL_M
  as select from ztravel_cosmo as Travel -- ztravel_cosmothe travel table is the data source for this view
  composition [0..*] of Z_I_BOOKING_M            as _Booking   --First child Booking entity 

--Associations for text info and value helps REUSE Views
  association [0..1] to /DMO/I_Agency            as _Agency        on $projection.agency_id = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer          as _Customer      on $projection.customer_id = _Customer.CustomerID
  association [0..1] to I_Currency               as _Currency      on $projection.currency_code = _Currency.Currency
  association [1..1] to /DMO/I_Overall_Status_VH as _OverallStatus on $projection.overall_status = _OverallStatus.OverallStatus


{

  key travel_id,
      agency_id,
      customer_id,
      begin_date,
      end_date,
      @Semantics.amount.currencyCode: 'currency_code'
      booking_fee,
      @Semantics.amount.currencyCode: 'currency_code'
      total_price,
      currency_code,
      overall_status,
      /* 
       VIRTUAL/CALCULATED FIELD FOR COLOR 
       3 = Green (Accepted)
       2 = Yellow (Open/Warning)
       1 = Red (Cancelled/Error)
       0 = Neutral
*/
case overall_status
      when 'A' then 3 
      when 'O' then 2
      when 'X' then 1
      else 0
    end as StatusCriticality,
    
      description,
      @Semantics.user.createdBy: true
      created_by,
      @Semantics.systemDateTime.createdAt: true
      created_at,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by,
      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at,

      /* Associations */
      _Booking,
      _Agency,
      _Customer,
      _Currency,
      _OverallStatus
      
}
