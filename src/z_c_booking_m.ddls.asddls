@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z_C_BOOKING_M
  as projection on Z_I_BOOKING_M
{
  key travel_id,
  key booking_id,
      booking_date,
      @ObjectModel.text.element: ['CustomerName']
      customer_id,
      _Customer.LastName        as CustomerName,
      @ObjectModel.text.element: ['CarrierName']
      carrier_id,
      _Carrier.Name             as CarrierName,
      connection_id,
      flight_date,
      @Semantics.amount.currencyCode: 'currency_code'
      flight_price,
      currency_code,
      @ObjectModel.text.element: ['BookingStatusText']
      booking_status,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      last_changed_at,
      /* Associations */
      _BookingStatus,
      _BookSupplement : redirected to composition child Z_C_BOOKINGSUPPL_M,
      _Carrier,
      _Connection,
      _Customer,
      _Travel         : redirected to parent Z_C_TRAVEL_M
}
