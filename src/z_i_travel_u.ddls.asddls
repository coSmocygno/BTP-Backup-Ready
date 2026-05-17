@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel View- unmanaged'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_TRAVEL_U
  as select from /dmo/travel as Travel
  composition [0..*] of Z_I_BOOKING_U            as _Booking

  association [0..1] to /DMO/I_Agency           as _Agency       on $projection.AgencyID = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer         as _Customer     on $projection.CustomerID = _Customer.CustomerID
  association [0..1] to I_Currency              as _Currency     on $projection.CurrencyCode = _Currency.Currency
  association [1..1] to /DMO/I_Travel_Status_VH as _TravelStatus on $projection.Status = _TravelStatus.TravelStatus


{
  key Travel.travel_id     as TravelID,

      Travel.agency_id     as AgencyID,

      Travel.customer_id   as CustomerID,

      Travel.begin_date    as BeginDate,

      Travel.end_date      as EndDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      Travel.booking_fee   as BookingFee,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      Travel.total_price   as TotalPrice,

      Travel.currency_code as CurrencyCode,

      Travel.description   as Memo,

      Travel.status        as Status,
      
      
            /* 
       VIRTUAL/CALCULATED FIELD FOR COLOR 
       3 = Green (Accepted)
       2 = Yellow (Open/Warning)
       1 = Red (Cancelled/Error)
       0 = Neutral
*/
case status 
  when 'B' then 3
  when 'P' then 2
  when 'N' then 2
  when 'X' then 1
  else 0
    end as StatusCriticality,
      
       _TravelStatus._Text.Text     as StatusText,
      
      Travel.description   as Description,

      Travel.lastchangedat as LastChangedAt,
      
      //Associations
            _Booking,
      _Agency,
      _Customer,
      _Currency,
      _TravelStatus
}
