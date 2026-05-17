@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Connection Consumption View'
@Metadata.allowExtensions: true

@Search.searchable: true

define view entity Z_C_CONNECTION_COSMO
  as select from Z_I_CONNECTION_COSMO

  association [1..*] to Z_C_FLIGHT_COSMO as _Flight on  $projection.AirlineID    = _Flight.AirlineID
                                                   and $projection.ConnectionID = _Flight.ConnectionID
{
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Carrier_StdVH', element: 'AirlineID' }}]
      @ObjectModel.text.element: ['AirlineName']
  key AirlineID,
  key ConnectionID,

      _Airline.Name                                                  as AirlineName,

      concat( concat( AirlineID, '-' ), ltrim( ConnectionID, '0' ) ) as ConnectionTitle,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Airport_StdVH', element: 'AirportID' }, useForValidation: true }]
      @ObjectModel.text.element: ['DepartureAirportName']
      DepartureAirport,
      _AirportFrom.Name                                              as DepartureAirportName,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Airport_StdVH', element: 'AirportID' }, useForValidation: true }]
      @ObjectModel.text.element: ['DestinationAirportName']
      DestinationAirport,
      _AirportTo.Name                                                as DestinationAirportName,

      DepartureTime,
      ArrivalTime,
      Distance,
      DistanceUnit,

      /* Associations */
      @Search.defaultSearchElement: true
      _Flight,

      _Airline,
      _AirportFrom,
      _AirportTo
}
