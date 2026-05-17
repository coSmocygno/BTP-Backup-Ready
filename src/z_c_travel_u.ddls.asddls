@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Projection View-Unmanaged'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z_C_TRAVEL_U 
  provider contract transactional_query
as projection on Z_I_TRAVEL_U
{


@UI.lineItem: [ 
  { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept Travel', emphasized: true } 
]
@UI.identification: [ 
  { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept Travel', emphasized: true } 
]

   key TravelID,

      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Agency_StdVH', element: 'AgencyID'  }, useForValidation: true }]
      @ObjectModel.text.element: ['AgencyName']
      @Search.defaultSearchElement: true
      AgencyID,
      _Agency.Name       as AgencyName,

      @Consumption.valueHelpDefinition: [{entity: {name: '/DMO/I_Customer_StdVH', element: 'CustomerID' }, useForValidation: true}]
      @ObjectModel.text.element: ['CustomerName']
      @Search.defaultSearchElement: true
      
      CustomerID,
      _Customer.LastName as CustomerName,

      BeginDate,

      EndDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,

      @Consumption.valueHelpDefinition: [{entity: {name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true }]
      CurrencyCode,

      Memo,

    @Consumption.valueHelpDefinition: [{
  entity: {
    name: '/DMO/I_Travel_Status_VH',
    element: 'TravelStatus'
  }
}]
      @ObjectModel.text.element: ['StatusText']
      Status,
        @Semantics.text: true
      _TravelStatus._Text.Text as StatusText : localized,
      StatusCriticality,
      

      LastChangedAt,
      
            /* Associations */
      _Agency,
      _Booking : redirected to composition child Z_C_BOOKING_U,
      _Currency,
      _Customer,
      _TravelStatus
}
