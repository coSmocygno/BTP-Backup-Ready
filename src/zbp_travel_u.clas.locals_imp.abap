CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS rba_Booking FOR READ
      IMPORTING keys_rba FOR READ Travel\_Booking FULL result_requested RESULT result LINK association_links.

    METHODS cba_Booking FOR MODIFY
      IMPORTING entities_cba FOR CREATE Travel\_Booking.
    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.
    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.
*    METHODS earlynumbering_create FOR NUMBERING
*      IMPORTING entities FOR CREATE Travel.

*    METHODS earlynumbering_cba_Booking FOR NUMBERING
*      IMPORTING entities FOR CREATE Travel\_Booking.

    TYPES : tt_failed   TYPE TABLE FOR FAILED EARLY z_i_travel_u\\travel,
            tt_reported TYPE TABLE FOR REPORTED EARLY z_i_travel_u\\travel.

    METHODS map_messages
      IMPORTING
        cid          TYPE abp_behv_cid OPTIONAL
        messages     TYPE /dmo/t_message OPTIONAL
        travel_id    TYPE /dmo/travel_id
      EXPORTING
        failed_added TYPE abap_boolean
      CHANGING
        failed       TYPE tt_failed
        reported     TYPE tt_reported.

    TYPES tt_booking_failed   TYPE TABLE FOR FAILED   z_i_booking_u.
    TYPES tt_booking_reported TYPE TABLE FOR REPORTED z_i_booking_u.

    METHODS map_messages_assoc_to_booking
      IMPORTING
        cid          TYPE string
        is_dependend TYPE abap_bool DEFAULT abap_false
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_bool
      CHANGING
        failed       TYPE tt_booking_failed
        reported     TYPE tt_booking_reported.

    METHODS prepare.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travels).

    result = VALUE #(
      FOR travel IN lt_travels (

        %tky = travel-%tky

        %features-%action-acceptTravel =
          COND #(
            WHEN travel-Status = 'X'
              OR travel-Status = 'B'
            THEN if_abap_behv=>fc-o-disabled
            ELSE if_abap_behv=>fc-o-enabled
          )

        %features-%action-rejectTravel =
          COND #(
            WHEN travel-Status = 'X'
            THEN if_abap_behv=>fc-o-disabled
            ELSE if_abap_behv=>fc-o-enabled
          )

      )
    ).

    "feature control for bookings.
    READ ENTITIES OF z_i_travel_u IN LOCAL MODE
      ENTITY Travel
        FIELDS ( TravelID Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travel_read_results)
      FAILED failed.

    result = VALUE #(
      FOR travel_read_result IN travel_read_results (
        %tky            = travel_read_result-%tky


    "if already booked 'B' or rejected 'X' then disabling booking creation for that travel.
*        %assoc-_Booking = COND #( WHEN travel_read_result-Status = 'B' OR travel_read_result-Status = 'X'
*                                  THEN if_abap_behv=>fc-o-disabled
*                                  ELSE if_abap_behv=>fc-o-enabled )
      )
    ).


  READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

  result = VALUE #(

    FOR ls_travel IN lt_travel

    (

      %tky = ls_travel-%tky

      "-----------------------------------
      " UPDATE CONTROL
      "-----------------------------------
      %features-%update =
        COND #(
          WHEN ls_travel-Status = 'X'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

      "-----------------------------------
      " DELETE CONTROL
      "-----------------------------------
      %features-%delete =
        COND #(
          WHEN ls_travel-Status = 'B'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

      "-----------------------------------
      " ACCEPT ACTION
      "-----------------------------------
      %features-%action-acceptTravel =
        COND #(
          WHEN ls_travel-Status = 'B'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

      "-----------------------------------
      " REJECT ACTION
      "-----------------------------------
      %features-%action-rejectTravel =
        COND #(
          WHEN ls_travel-Status = 'X'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

    )

  ).


  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.

    DATA : ls_travel_in  TYPE /dmo/travel,
           ls_travel_out TYPE /dmo/travel,
           lt_messages   TYPE /dmo/t_message.
*         lv_failed_added TYPE boolean.

    LOOP AT entities INTO DATA(ls_entity).

      ls_travel_in = CORRESPONDING #( ls_entity MAPPING FROM ENTITY USING CONTROL ).

      ls_travel_out = ls_travel_out.
      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_CREATE'
        EXPORTING
          is_travel         = CORRESPONDING /dmo/s_travel_in( ls_travel_in )
*         it_booking        =
*         it_booking_supplement  =
          iv_numbering_mode = /dmo/if_flight_legacy=>numbering_mode-late
        IMPORTING
          es_travel         = ls_travel_out
*         et_booking        =
*         et_booking_supplement  =
          et_messages       = lt_messages.

      map_messages(
      EXPORTING
      messages = lt_messages
      cid     = ls_entity-%cid
      travel_id = ls_travel_out-travel_id
      IMPORTING
      failed_added  = DATA(lv_failed_added)
      CHANGING
      failed = failed-travel
      reported = reported-travel
      ).

      IF lv_failed_added = abap_false.
        "If no failed entry was added, we can add a success message to the reported structure
        INSERT VALUE #( %cid = ls_entity-%cid
                        TravelID = ls_travel_out-travel_id
                         ) INTO TABLE mapped-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA: lt_messages  TYPE /dmo/t_message,
          ls_travel_in TYPE /dmo/travel,
          ls_travelx   TYPE /dmo/s_travel_inx. "refers to x structure (> BAPIs)

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_update>).

      ls_travel_in = CORRESPONDING #( <travel_update> MAPPING FROM ENTITY ).

      ls_travelx-travel_id = <travel_update>-TravelID.
      ls_travelx-_intx     = CORRESPONDING #( <travel_update> MAPPING FROM ENTITY ).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
        EXPORTING
          is_travel   = CORRESPONDING /dmo/s_travel_in( ls_travel_in )
          is_travelx  = ls_travelx
        IMPORTING
          et_messages = lt_messages.

      map_messages(
          EXPORTING
          cid     = <travel_update>-%cid_ref
          travel_id = <travel_update>-travelid
          messages = lt_messages
          CHANGING
          failed = failed-travel
          reported = reported-travel
          ).

    ENDLOOP.

  ENDMETHOD.

  METHOD delete.
    DATA: lt_messages TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_keys>).

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_DELETE'
        EXPORTING
          iv_travel_id = <ls_keys>-travelid
        IMPORTING
          et_messages  = lt_messages.

      map_messages(
        EXPORTING
          cid       = <ls_keys>-%cid_ref
          travel_id = <ls_keys>-travelid
          messages  = lt_messages
        CHANGING
          failed    = failed-travel
          reported  = reported-travel
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    DATA: ls_travel_out TYPE /dmo/travel,
          lt_messages   TYPE /dmo/t_message.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_keys>) GROUP BY <ls_keys>-%tky.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <ls_keys>-TravelID
        IMPORTING
          es_travel    = ls_travel_out
          et_messages  = lt_messages.

      map_messages(
        EXPORTING
          travel_id    = <ls_keys>-TravelID
          messages     = lt_messages
        IMPORTING
          failed_added = DATA(failed_added)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

      IF failed_added = abap_false.
        INSERT CORRESPONDING #( ls_travel_out MAPPING TO ENTITY ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD lock.

    TRY.
        "if we give /DMO/TRAVEL we get a dump so we need to pass /DMO/ETRAVEL
        DATA(lr_lock) = cl_abap_lock_object_factory=>get_instance( iv_name = '/DMO/ETRAVEL' ).
      CATCH cx_abap_lock_failure INTO DATA(lo_lock_fail).

        RAISE SHORTDUMP lo_lock_fail.
        "handle exception
    ENDTRY.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      TRY.
          lr_lock->enqueue(
*            it_table_mode =
            it_parameter  = VALUE #( ( name = 'TRAVEL_ID' value = REF #( <ls_key>-TravelID ) ) )
*            _scope        =
*            _wait         =
          ).

        CATCH cx_abap_foreign_lock INTO DATA(lr_fo_lock).

          map_messages(
                   EXPORTING
                        travel_id = <ls_key>-TravelID
                        messages  =  VALUE #( (
                                                   msgid = '/DMO/CM_FLIGHT_LEGAC'
                                                   msgty = 'E'
                                                   msgno = '032'
                                                   msgv1 = <ls_key>-travelid
                                                   msgv2 = lr_fo_lock->user_name )
                                  )
                      CHANGING
                        failed    = failed-travel
                        reported  = reported-travel
                    ).

        CATCH cx_abap_lock_failure INTO lo_lock_fail.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Booking.

    DATA: travel_out  TYPE /dmo/travel,
          booking_out TYPE /dmo/t_booking,
          booking     LIKE LINE OF result,
          messages    TYPE /dmo/t_message.

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<travel_rba>) GROUP BY <travel_rba>-TravelID.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = <travel_rba>-travelid
        IMPORTING
          es_travel    = travel_out
          et_booking   = booking_out
          et_messages  = messages.

      map_messages(
        EXPORTING
          travel_id    = <travel_rba>-TravelID
          messages     = messages
        IMPORTING
          failed_added = DATA(failed_added)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

      IF failed_added = abap_false.
        LOOP AT booking_out ASSIGNING FIELD-SYMBOL(<booking>).
          "fill link table with key fields
          INSERT
            VALUE #(
              source-%tky = <travel_rba>-%tky
              target-%tky = VALUE #(
                              TravelID  = <booking>-travel_id
                              BookingID = <booking>-booking_id
                            )
            ) INTO TABLE association_links.

          IF result_requested = abap_true.
            booking = CORRESPONDING #( <booking> MAPPING TO ENTITY ).
            INSERT booking INTO TABLE result.
          ENDIF.

        ENDLOOP.
      ENDIF.

    ENDLOOP.

    SORT association_links BY target ASCENDING.
    DELETE ADJACENT DUPLICATES FROM association_links COMPARING ALL FIELDS.

    SORT result BY %tky ASCENDING.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.

  ENDMETHOD.

  METHOD cba_Booking.

    DATA: messages        TYPE /dmo/t_message,
          booking_old     TYPE /dmo/t_booking,
          booking         TYPE /dmo/booking,
          last_booking_id TYPE /dmo/booking_id VALUE '0'.

    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<travel>).

      DATA(travelid) = <travel>-travelid.

      CALL FUNCTION '/DMO/FLIGHT_TRAVEL_READ'
        EXPORTING
          iv_travel_id = travelid
        IMPORTING
          et_booking   = booking_old
          et_messages  = messages.

      map_messages(
        EXPORTING
          cid       = <travel>-%cid_ref
          travel_id = <travel>-TravelID
          messages  = messages
        IMPORTING
          failed_added = DATA(failed_added)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

      IF failed_added = abap_true.
        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking>).
          map_messages_assoc_to_booking(
            EXPORTING
              cid         = <booking>-%cid
              is_dependend = abap_true
              messages    = messages
            CHANGING
              failed      = failed-booking
              reported    = reported-booking
          ).
        ENDLOOP.

      ELSE.

        " Set the last_booking_id to the highest value of booking_old booking_id or initial value if none exist
        last_booking_id = VALUE #( booking_old[ lines( booking_old ) ]-booking_id OPTIONAL ).

        LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_create>).

          booking = CORRESPONDING #( <booking_create> MAPPING FROM ENTITY  ). "USING CONTROL

          last_booking_id += 1.
          booking-booking_id = last_booking_id.

          CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
            EXPORTING
              is_travel   = VALUE /dmo/s_travel_in( travel_id = travelid )
              is_travelx  = VALUE /dmo/s_travel_inx( travel_id = travelid )
              it_booking  = VALUE /dmo/t_booking_in( ( CORRESPONDING #( booking ) ) )
              it_bookingx = VALUE /dmo/t_booking_inx(
                (
                  booking_id  = booking-booking_id
                  action_code = /dmo/if_flight_legacy=>action_code-create
                )
              )
            IMPORTING
              et_messages = messages.

          map_messages_assoc_to_booking(
            EXPORTING
              cid          = <booking_create>-%cid
              messages     = messages
            IMPORTING
              failed_added = failed_added
            CHANGING
              failed       = failed-booking
              reported     = reported-booking
          ).

          IF failed_added = abap_false.
            INSERT
              VALUE #(
                %cid      = <booking_create>-%cid
                travelid  = travelid
                bookingid = booking-booking_id
              ) INTO TABLE mapped-booking.
          ENDIF.

        ENDLOOP.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.


  METHOD map_messages.

    "This is a helper method used to convert traditional SAP messages (from a Function Module)
    "into the RAP-specific FAILED and REPORTED structures so the UI can display errors correctly.

    failed_added = abap_false.
    LOOP AT messages INTO DATA(ls_message).

      IF ls_message-msgty = 'E' OR ls_message-msgty = 'A'.

        APPEND VALUE #( %cid = cid
        travelid = travel_id
                        %fail-cause = zcl_travel_aux=>get_cause_from_message(
                        msgid = ls_message-msgid
                        msgno = ls_message-msgno
                        )
         )
         TO failed.
        failed_added = abap_true.
      ENDIF.

      reported = VALUE #( ( %cid = cid
                            travelid = travel_id
                            %msg = new_message(
                             id = ls_message-msgid
                            number = ls_message-msgno
                            severity = if_abap_behv_message=>severity-error
                            v1 = ls_message-msgv1
                            v2 = ls_message-msgv2
                            v3 = ls_message-msgv3
                            v4 = ls_message-msgv4
                            )  ) ).

    ENDLOOP.

  ENDMETHOD.

  METHOD acceptTravel.

 DATA:
    lt_messages TYPE /dmo/t_message,
    ls_travelx  TYPE /dmo/s_travel_inx.

  DATA lt_current TYPE TABLE FOR READ RESULT Z_I_Travel_U.

  FIELD-SYMBOLS:
    <ls_key>    LIKE LINE OF keys,
    <ls_travel> LIKE LINE OF lt_current.

  LOOP AT keys ASSIGNING <ls_key>.

    CLEAR:
      lt_messages,
      ls_travelx.

    "Read selected travel
    READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
      ENTITY Travel
      FIELDS ( TravelID Status )
      WITH VALUE #(
        (
          TravelID = <ls_key>-TravelID
        )
      )
      RESULT lt_current.

    READ TABLE lt_current ASSIGNING <ls_travel> INDEX 1.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DATA(lv_status) = <ls_travel>-Status.

IF lv_status = 'B'.

  "Mark action as failed
  APPEND VALUE #(
    %tky = <ls_travel>-%tky
  ) TO failed-travel.

  "Error popup
  APPEND VALUE #(
    %tky = <ls_travel>-%tky
    %msg = new_message_with_text(
             severity = if_abap_behv_message=>severity-error
             text     = |Travel { <ls_travel>-TravelID } Already Booked|
           )
  ) TO reported-travel.

  CONTINUE.

ENDIF.

    "Accept/Book the travel
    CASE lv_status.

      WHEN 'N' OR 'P' OR 'X'.
        lv_status = 'B'.

      WHEN OTHERS.
        CONTINUE.

    ENDCASE.

    "Prepare X structure for legacy FM
    ls_travelx-travel_id = <ls_travel>-TravelID.
    ls_travelx-status    = abap_true.

    "Legacy FM call
    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
      EXPORTING
        is_travel = VALUE /dmo/s_travel_in(
                      travel_id = <ls_travel>-TravelID
                      status    = lv_status )

        is_travelx = ls_travelx

      IMPORTING
        et_messages = lt_messages.

    "Map messages from FM
    map_messages(
      EXPORTING
        travel_id    = <ls_travel>-TravelID
        messages     = lt_messages
      IMPORTING
        failed_added = DATA(lv_failed)
      CHANGING
        failed       = failed-travel
        reported     = reported-travel
    ).

    "If update successful
    IF lv_failed IS INITIAL.

      "Update RAP transactional buffer
      MODIFY ENTITIES OF Z_I_Travel_U IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          (
            %tky   = <ls_travel>-%tky
            Status = lv_status
          )
        ).

      "Success popup
      APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %msg = new_message_with_text(
           severity = if_abap_behv_message=>severity-success
           text     = |Travel { <ls_travel>-TravelID } booked successfully|
         )
      ) TO reported-travel.

    ENDIF.

  ENDLOOP.

  "Read updated entities
  READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_result).

  "Return updated result to FE
  result = VALUE #(
    FOR ls_result IN lt_travel_result
    (
      %tky   = ls_result-%tky
      %param = ls_result
    )
  ).


  ENDMETHOD.

  METHOD map_messages_assoc_to_booking.

    ASSERT cid IS NOT INITIAL. "In a create case, the %cid has to be present
    failed_added = abap_false.

    LOOP AT messages INTO DATA(message).
      IF message-msgty = 'E' OR message-msgty = 'A'.
        APPEND VALUE #( %cid        = cid
                        %fail-cause = /dmo/cl_travel_auxiliary=>get_cause_from_message(
                                        msgid        = message-msgid
                                        msgno        = message-msgno
                                        is_dependend = is_dependend
                                      ) ) TO failed.
        failed_added = abap_true.
      ENDIF.

      APPEND VALUE #( %msg = new_message(
                               id       = message-msgid
                               number   = message-msgno
                               severity = if_abap_behv_message=>severity-error
                               v1       = message-msgv1
                               v2       = message-msgv2
                               v3       = message-msgv3
                               v4       = message-msgv4 )
                      %cid = cid ) TO reported.
    ENDLOOP.

  ENDMETHOD.

  METHOD calculateTotalPrice.

    READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
      ENTITY Travel
      FIELDS ( BookingFee TotalPrice )
      WITH VALUE #( FOR key IN keys
       ( %tky = key-%tky ) )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      <travel>-TotalPrice = <travel>-BookingFee + 100.

    ENDLOOP.

    MODIFY ENTITIES OF Z_I_Travel_U IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( TotalPrice )
      WITH VALUE #(
        FOR travel IN travels
        (
          %tky       = travel-%tky
          TotalPrice = travel-TotalPrice
        )
      ).

  ENDMETHOD.

*  METHOD earlynumbering_create.
*
*
*    DATA: lv_max_travel_id TYPE /dmo/travel_id.
*
*    " Select the highest ID. We use the actual table to ensure we are
*    " getting the latest persistent number.
*    SELECT MAX( travel_id ) FROM ztravel_cosmo INTO @lv_max_travel_id.
*
*    " If the table was empty or the max returned is 0, start at a base number
*    IF lv_max_travel_id IS INITIAL.
*      lv_max_travel_id = '00000000'.
*    ENDIF.
*
*    LOOP AT entities INTO DATA(ls_entity).
*      " This increment handles the string-to-int conversion automatically
*      lv_max_travel_id += 1.
*
*      APPEND VALUE #( %cid      = ls_entity-%cid
*                      TravelID = lv_max_travel_id )
*             TO mapped-travel.
*    ENDLOOP.
*
*  ENDMETHOD.

*  METHOD earlynumbering_cba_Booking.
*
*
*    DATA : lv_max_booking_id TYPE /dmo/booking_id.
*
*    " Select the highest ID. We use the actual table to ensure we are
*    " getting the latest persistent number.
**    SELECT MAX( booking_id ) FROM zbooking_cosmo INTO @lv_max_booking_id.
*
*    " using read entities by association and link data to just get link between all bookings of the travel.
*    " !!!!USE local mode when implementing own behaviour def.
*
*    READ ENTITIES OF z_i_travel_u IN LOCAL MODE
*        ENTITY travel BY \_booking
*          FROM CORRESPONDING #( entities )
*          LINK DATA(lt_link_data).   "inline declaration we get travel and booking link F2 for details
*
*    "loop by group by and we will use reduce operation to get maximum one from entities data.
*    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>) GROUP BY <ls_entity>-TravelID.
*      " we will use reduce operation to get maximum one from entities data.
*      lv_max_booking_id = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
*                                                FOR ls_link IN lt_link_data USING KEY entity
*                                                WHERE ( source-travelid = <ls_entity>-travelid )
*                                                NEXT lv_max = COND /DMO/booking_id( WHEN lv_max < ls_link-target-BookingID THEN ls_link-target-BookingID ELSE lv_max ) ).
*
*      lv_max_booking_id = REDUCE #( INIT lv_max = lv_max_booking_id
*                                                  FOR ls_entity IN entities USING KEY entity
*                                                  WHERE ( travelid = <ls_entity>-travelid )
*                                                  FOR ls_booking IN ls_entity-%target
*                                                  NEXT lv_max = COND /DMO/booking_id( WHEN lv_max < ls_booking-bookingid THEN ls_booking-bookingid ELSE lv_max ) ).
*
*      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>) USING KEY entity
*      WHERE travelid = <ls_entity>-travelid.
*
*        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).
*          IF <ls_booking>-bookingid IS INITIAL.
*
*            " This increment handles the string-to-int conversion automatically
*            lv_max_booking_id += 1.
*
*            APPEND CORRESPONDING #( <ls_booking> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<ls_new_mapped_booking>).
*
*            "the new booking_id stored here through lv_max_booking_id.
*            <ls_new_mapped_booking>-BookingID = lv_max_booking_id.
*          ENDIF.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*
*  ENDMETHOD.

  METHOD rejectTravel.


  DATA:
    lt_messages TYPE /dmo/t_message,
    ls_travelx  TYPE /dmo/s_travel_inx.

  "1. Read current data
  READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelID Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_current).

  LOOP AT lt_travel_current ASSIGNING FIELD-SYMBOL(<ls_travel>).

    CLEAR:
      ls_travelx,
      lt_messages.

    "Already canceled
    IF <ls_travel>-Status = 'X'.

      "Mark action as failed
  APPEND VALUE #(
    %tky = <ls_travel>-%tky
  ) TO failed-travel.

   "Error popup
      APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = |Travel { <ls_travel>-TravelID } Already Canceled|
               )
      ) TO reported-travel.

      "Return current entity
      APPEND VALUE #(
        %tky   = <ls_travel>-%tky
        %param = <ls_travel>
      ) TO result.

      CONTINUE.

    ENDIF.

    "Reject/Cancel status
    DATA(lv_status) = 'X'.

    "2. Update via Legacy FM
    ls_travelx-travel_id = <ls_travel>-TravelID.
    ls_travelx-status    = abap_true.

    CALL FUNCTION '/DMO/FLIGHT_TRAVEL_UPDATE'
      EXPORTING
        is_travel = VALUE /dmo/s_travel_in(
                      travel_id = <ls_travel>-TravelID
                      status    = lv_status )

        is_travelx = ls_travelx

      IMPORTING
        et_messages = lt_messages.

    "3. Update RAP buffer
    IF lt_messages IS INITIAL.

      MODIFY ENTITIES OF Z_I_Travel_U IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          (
            %tky   = <ls_travel>-%tky
            Status = lv_status
          )
        ).

      "Success popup message
      APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Travel { <ls_travel>-TravelID } canceled successfully|
               )
      ) TO reported-travel.

    ELSE.

      "Map FM error messages
      map_messages(
        EXPORTING
          travel_id    = <ls_travel>-TravelID
          messages     = lt_messages
        IMPORTING
          failed_added = DATA(lv_failed)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

    ENDIF.

  ENDLOOP.

  "4. Refresh UI result
  READ ENTITIES OF Z_I_Travel_U IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_result).

  result = VALUE #(
    FOR ls_travel_res IN lt_travel_result
    (
      %tky   = ls_travel_res-%tky
      %param = ls_travel_res
    )
  ).

ENDMETHOD.

  METHOD validateCustomer.

   "Read current draft/transactional data
  READ ENTITIES OF Z_I_Travel_U
  IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelID CustomerID )
  WITH VALUE #( FOR key IN keys
    ( %tky = key-%tky ) )
  RESULT DATA(lt_travel).


  LOOP AT lt_travel INTO DATA(ls_travel).

    "Skip empty customer
    IF ls_travel-CustomerID IS INITIAL.
      CONTINUE.
    ENDIF.

    "Check customer existence
    SELECT SINGLE customer_id
      FROM /dmo/customer
      WHERE customer_id = @ls_travel-CustomerID
      INTO @DATA(lv_customer).

    IF sy-subrc <> 0.

      "Mark validation failure
      APPEND VALUE #(
        %tky = ls_travel-%tky
      ) TO failed-travel.

      "Error popup/message
      APPEND VALUE #(
        %tky = ls_travel-%tky

        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = |Customer { ls_travel-CustomerID } does not exist|
               )

        %element-CustomerID = if_abap_behv=>mk-on

      ) TO reported-travel.

    ENDIF.

  ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.

READ ENTITIES OF z_i_travel_u
  IN LOCAL MODE
  ENTITY Travel
  "ALL FIELDS
  FIELDS ( TravelID BeginDate EndDate )
  WITH VALUE #( FOR key IN keys
    ( %tky = key-%tky ) )
  RESULT DATA(lt_travel).

  LOOP AT lt_travel INTO DATA(ls_travel).

    IF ls_travel-EndDate < ls_travel-BeginDate.

      APPEND VALUE #(
        %tky = ls_travel-%tky
      ) TO failed-travel.

      APPEND VALUE #(
        %tky = ls_travel-%tky
        %element-EndDate = if_abap_behv=>mk-on
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text = |End Date cannot be before Begin Date|
               )
      ) TO reported-travel.

    ENDIF.

  ENDLOOP.


  ENDMETHOD.

  METHOD prepare.
ENDMETHOD.

ENDCLASS.
