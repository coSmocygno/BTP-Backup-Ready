@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Consumption View'
@Metadata.allowExtensions: true

@Search.searchable: true

define view entity Z_C_FLIGHT_COSMO
  as select from Z_I_FLIGHT_COSMO
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @ObjectModel.text.element: ['AirlineName']
  key AirlineID,
  key ConnectionID,
  key FlightDate,

      _Airline.Name as AirlineName,

      Price,
      CurrencyCode,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      PlaneType,
      MaximumSeats,
      OccupiedSeats,
      OccupiedSeats as OccupiedSeatsForChart,

      /* Associations */
      _Airline
}
