CLASS zcl_abapgit_data_factory DEFINITION
  PUBLIC
  CREATE PUBLIC
  GLOBAL FRIENDS zcl_abapgit_data_injector .

  PUBLIC SECTION.

    METHODS get_serializer
      RETURNING
        VALUE(ri_serializer) TYPE REF TO zif_abapgit_data_serializer .
    METHODS get_deserializer
      RETURNING
        VALUE(ri_deserializer) TYPE REF TO zif_abapgit_data_deserializer .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-DATA gi_serializer TYPE REF TO zif_abapgit_data_serializer .
    CLASS-DATA gi_deserializer TYPE REF TO zif_abapgit_data_deserializer .
ENDCLASS.



CLASS ZCL_ABAPGIT_DATA_FACTORY IMPLEMENTATION.


  METHOD get_deserializer.

    IF gi_deserializer IS INITIAL.
      gi_deserializer = NEW zcl_abapgit_data_deserializer( ).
    ENDIF.

    ri_deserializer = gi_deserializer.

  ENDMETHOD.


  METHOD get_serializer.

    IF gi_serializer IS INITIAL.
      gi_serializer = NEW zcl_abapgit_data_serializer( ).
    ENDIF.

    ri_serializer = gi_serializer.

  ENDMETHOD.
ENDCLASS.
