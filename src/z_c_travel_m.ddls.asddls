@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_C_TRAVEL_M
  provider contract transactional_query
  as projection on Z_I_TRAVEL_M
{
  key travel_id,
      @ObjectModel.text.element: ['AgencyName']
      agency_id,
      _Agency.Name              as AgencyName,
      @ObjectModel.text.element: ['CustomerName']
      customer_id,
      _Customer.LastName        as CustomerName,
      begin_date,
      end_date,
      @Semantics.amount.currencyCode: 'currency_code'
      booking_fee,
      @Semantics.amount.currencyCode: 'currency_code'
      total_price,
      currency_code,
      @ObjectModel.text.element: ['OverallStatusText']
      overall_status,
      StatusCriticality,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      description,
      created_by,
      created_at,
      last_changed_by,
      last_changed_at,
      /* Associations */
      _Agency,
      _Booking : redirected to composition child Z_C_BOOKING_M,
      _Currency,
      _Customer,
      _OverallStatus
}
