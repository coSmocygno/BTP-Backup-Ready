@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z_C_BOOKINGSUPPL_M
  as projection on Z_I_BOOKSUPPL_M
{
  key travel_id,
  key booking_id,
  key booking_supplement_id,
      @ObjectModel.text.element: [ 'supplementDescrip' ]
      supplement_id,
      _SupplementText.Description as SupplementDescrip : localized,
      @Semantics.amount.currencyCode: 'currency_code'
      price,
      currency_code,
      last_changed_at,
      /* Associations */
      _Booking : redirected to parent Z_C_BOOKING_M,
      _Product,
      _SupplementText,
      _Travel  : redirected to Z_C_TRAVEL_M
}
