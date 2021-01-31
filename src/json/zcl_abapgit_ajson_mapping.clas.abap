CLASS zcl_abapgit_ajson_mapping DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create_camel_case
      IMPORTING
        it_mapping_fields   TYPE zif_abapgit_ajson_mapping=>ty_mapping_fields OPTIONAL
        iv_first_json_upper TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(ri_mapping)   TYPE REF TO zif_abapgit_ajson_mapping.

    CLASS-METHODS create_upper_case
      IMPORTING
        it_mapping_fields TYPE zif_abapgit_ajson_mapping=>ty_mapping_fields OPTIONAL
      RETURNING
        VALUE(ri_mapping) TYPE REF TO zif_abapgit_ajson_mapping.

    CLASS-METHODS create_lower_case
      IMPORTING
        it_mapping_fields TYPE zif_abapgit_ajson_mapping=>ty_mapping_fields OPTIONAL
      RETURNING
        VALUE(ri_mapping) TYPE REF TO zif_abapgit_ajson_mapping.

    CLASS-METHODS create_field_mapping
      IMPORTING
        it_mapping_fields TYPE zif_abapgit_ajson_mapping=>ty_mapping_fields
      RETURNING
        VALUE(ri_mapping) TYPE REF TO zif_abapgit_ajson_mapping.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_abapgit_ajson_mapping IMPLEMENTATION.


  METHOD create_camel_case.

    ri_mapping = NEW lcl_mapping_camel( it_mapping_fields = it_mapping_fields
                                        iv_first_json_upper = iv_first_json_upper ).

  ENDMETHOD.


  METHOD create_upper_case.

    ri_mapping = NEW lcl_mapping_to_upper( it_mapping_fields = it_mapping_fields ).

  ENDMETHOD.


  METHOD create_lower_case.

    ri_mapping = NEW lcl_mapping_to_lower( it_mapping_fields = it_mapping_fields ).

  ENDMETHOD.


  METHOD create_field_mapping.

    ri_mapping = NEW lcl_mapping_fields( it_mapping_fields = it_mapping_fields ).

  ENDMETHOD.


ENDCLASS.
