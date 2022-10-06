CLASS zcl_abapgit_json_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_json_abap_mapping,
        json TYPE string,
        abap TYPE string,
      END OF ty_json_abap_mapping,
      ty_json_abap_mappings TYPE STANDARD TABLE OF ty_json_abap_mapping WITH DEFAULT KEY,
      BEGIN OF ty_enum_mapping,
        path     TYPE string,
        mappings TYPE ty_json_abap_mappings,
      END OF ty_enum_mapping,
      ty_enum_mappings TYPE TABLE OF ty_enum_mapping WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_path_value_pair,
        path  TYPE string,
        value TYPE string,
      END OF ty_path_value_pair,
      ty_skip_paths TYPE STANDARD TABLE OF ty_path_value_pair WITH KEY path.

    "! Serializes data to xstring. Type of data is specified in the
    "! implementing class.
    "!
    "! @parameter iv_data | data to be serialized
    "! @parameter iv_enum_mappings | ABAP/JSON value mappings
    "! @parameter iv_skip_paths | path/value pairs to be skipped during serialization
    "! @parameter rv_result | serialized data
    METHODS serialize
      IMPORTING iv_data          TYPE data
                iv_enum_mappings TYPE ty_enum_mappings
                iv_skip_paths    TYPE ty_skip_paths
      RETURNING VALUE(rv_result) TYPE xstring
      RAISING   cx_static_check.

    "! Deserializes xstring into data. The type of data is specified in
    "! the implementing class
    "!
    "! @parameter iv_content | xstring to be deserialized
    "! @parameter iv_defaults | path-value pairs that apply if value is initial
    "! @parameter ev_data | data of the xstring
    METHODS deserialize
      IMPORTING iv_content       TYPE xstring
                iv_defaults      TYPE ty_skip_paths
                iv_enum_mappings TYPE ty_enum_mappings
      EXPORTING ev_data          TYPE data
      RAISING   cx_static_check.


  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS:
      map2json_original_language
        CHANGING co_ajson TYPE REF TO zcl_abapgit_ajson
        RAISING  zcx_abapgit_ajson_error,
      map2json_custom_enum
        IMPORTING it_enum_mappings TYPE ty_enum_mappings
        CHANGING  co_ajson         TYPE REF TO zcl_abapgit_ajson
        RAISING   zcx_abapgit_ajson_error,
      map2json_abap_language_version
        CHANGING co_ajson TYPE REF TO zcl_abapgit_ajson
        RAISING  zcx_abapgit_ajson_error,
      "! Get the enum mapping from object handler, as other enums as well
      map2abap_abap_language_version
        CHANGING co_ajson TYPE REF TO zcl_abapgit_ajson
        RAISING  zcx_abapgit_ajson_error,
      "! For deserialization
      map2abap_original_language
        CHANGING co_ajson TYPE REF TO zcl_abapgit_ajson
        RAISING  zcx_abapgit_ajson_error,
      "! For deserialization
      set_defaults
        IMPORTING it_defaults TYPE ty_skip_paths
        CHANGING  co_ajson    TYPE REF TO zcl_abapgit_ajson
        RAISING   zcx_abapgit_ajson_error,
      map2abap_custom_enum
        IMPORTING it_enum_mappings TYPE ty_enum_mappings
        CHANGING  co_ajson         TYPE REF TO zcl_abapgit_ajson
        RAISING   zcx_abapgit_ajson_error.

ENDCLASS.



CLASS zcl_abapgit_json_handler IMPLEMENTATION.


  METHOD deserialize.
    DATA lv_json    TYPE string.
    DATA lo_ajson   TYPE REF TO zcl_abapgit_ajson.
    DATA lo_mapping TYPE REF TO zif_abapgit_ajson_mapping.

    CLEAR ev_data.

    lv_json = zcl_abapgit_convert=>xstring_to_string_utf8( iv_content ).
    lo_mapping = zcl_abapgit_ajson_mapping=>create_camel_case( ).

    lo_ajson = zcl_abapgit_ajson=>parse( iv_json           = lv_json
                                         ii_custom_mapping = lo_mapping ).


    map2abap_original_language( CHANGING co_ajson = lo_ajson ).
    set_defaults( EXPORTING it_defaults = iv_defaults
                  CHANGING  co_ajson    = lo_ajson ).
    map2abap_abap_language_version( CHANGING co_ajson = lo_ajson ).
    map2abap_custom_enum( EXPORTING it_enum_mappings = iv_enum_mappings
                          CHANGING co_ajson          = lo_ajson  ).

    lo_ajson->zif_abapgit_ajson~to_abap( IMPORTING ev_container = ev_data ).

  ENDMETHOD.


  METHOD serialize.
    DATA: lt_st_source      TYPE abap_trans_srcbind_tab,
          lo_mapping        TYPE REF TO zif_abapgit_ajson_mapping,
          lv_json           TYPE string,
          lo_ajson          TYPE REF TO zcl_abapgit_ajson,
          lo_ajson_filtered TYPE REF TO zif_abapgit_ajson,
          lv_enum_abap      TYPE string,
          lo_filter         TYPE REF TO lcl_aff_filter.

    FIELD-SYMBOLS: <lg_source> LIKE LINE OF lt_st_source.

    APPEND INITIAL LINE TO lt_st_source ASSIGNING <lg_source>.
    GET REFERENCE OF iv_data INTO <lg_source>-value.

    lo_mapping = zcl_abapgit_ajson_mapping=>create_camel_case( iv_first_json_upper = abap_false ).

    lo_ajson = zcl_abapgit_ajson=>create_empty( lo_mapping ).

    lo_ajson->keep_item_order( ).
    lo_ajson->set(
      iv_path = '/'
      iv_val  = iv_data ).

    map2json_original_language( CHANGING co_ajson = lo_ajson ).
    map2json_abap_language_version( CHANGING co_ajson = lo_ajson ).
    map2json_custom_enum( EXPORTING it_enum_mappings = iv_enum_mappings
                          CHANGING co_ajson          = lo_ajson ).

    lo_filter = NEW #( iv_skip_paths = iv_skip_paths ).
    lo_ajson_filtered = zcl_abapgit_ajson=>create_from(
                          ii_source_json = lo_ajson
                          ii_filter      = lo_filter ).

    lo_ajson_filtered->keep_item_order( ).

    lv_json = lo_ajson_filtered->stringify( 2 ).

    " files end with an empty line (EOF)
    lv_json = lv_json && cl_abap_char_utilities=>newline.

    rv_result = zcl_abapgit_convert=>string_to_xstring_utf8( lv_json ).
  ENDMETHOD.

  METHOD map2json_original_language.
    DATA:
      lv_iso_language      TYPE i18_a_langiso2,
      lv_original_language TYPE sy-langu.


    lv_original_language = co_ajson->get_string( '/header/originalLanguage' ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
      EXPORTING
        input  = lv_original_language
      IMPORTING
        output = lv_iso_language.

    TRANSLATE lv_iso_language TO LOWER CASE.
    co_ajson->set_string( iv_path = '/header/originalLanguage'
                          iv_val  = lv_iso_language ).
  ENDMETHOD.

  METHOD map2json_abap_language_version.
    DATA:
      lv_enum_abap TYPE string,
      lv_enum_json TYPE string.


    lv_enum_abap = co_ajson->get_string( '/header/abapLanguageVersion' ).
    IF lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version_src-standard
      OR lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version-standard.
      lv_enum_json = 'standard'.
    ELSEIF lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version-cloud_development.
      lv_enum_json = 'cloudDevelopment'.
    ELSEIF lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version-key_user.
      lv_enum_json = 'keyUser'.
    ENDIF.

    co_ajson->set_string( iv_path = '/header/abapLanguageVersion'
                          iv_val  = lv_enum_json ).
  ENDMETHOD.

  METHOD map2abap_abap_language_version.
    DATA:
      lv_enum_abap TYPE string,
      lv_enum_json TYPE string.


    lv_enum_json = co_ajson->get_string( '/header/abapLanguageVersion' ).
    IF lv_enum_json = 'standard'.
      lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version_src-standard.
    ELSEIF lv_enum_json = 'cloudDevelopment'.
      lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version-cloud_development.
    ELSEIF lv_enum_json = 'keyUser'.
      lv_enum_abap = zif_abapgit_aff_types_v1=>co_abap_language_version-key_user.
    ENDIF.

    co_ajson->set_string( iv_path = '/header/abapLanguageVersion'
                          iv_val  = lv_enum_abap ).
  ENDMETHOD.

  METHOD map2json_custom_enum.
    DATA:
      lv_enum_abap    TYPE string,
      ls_enum_mapping TYPE ty_enum_mapping,
      ls_mapping      TYPE ty_json_abap_mapping.


    LOOP AT it_enum_mappings INTO ls_enum_mapping.
      lv_enum_abap = co_ajson->get_string( ls_enum_mapping-path ).
      READ TABLE ls_enum_mapping-mappings WITH KEY abap = lv_enum_abap INTO ls_mapping.
      IF sy-subrc = 0.
        co_ajson->set_string( iv_path = ls_enum_mapping-path
                              iv_val  = ls_mapping-json ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD map2abap_custom_enum.
    DATA:
      lv_enum_json    TYPE string,
      ls_enum_mapping TYPE ty_enum_mapping,
      ls_mapping      TYPE ty_json_abap_mapping.


    LOOP AT it_enum_mappings INTO ls_enum_mapping.
      lv_enum_json = co_ajson->get_string( ls_enum_mapping-path ).
      READ TABLE ls_enum_mapping-mappings WITH KEY json = lv_enum_json INTO ls_mapping.
      IF sy-subrc = 0.
        co_ajson->set_string( iv_path = ls_enum_mapping-path
                              iv_val  = ls_mapping-abap ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD set_defaults.
    DATA:
      lv_enum_json TYPE string,
      ls_default   TYPE ty_path_value_pair.


    LOOP AT it_defaults INTO ls_default.
      lv_enum_json = co_ajson->get_string( ls_default-path ).
      IF lv_enum_json = ``.
        co_ajson->set_string( iv_path = ls_default-path
                              iv_val  = ls_default-value ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD map2abap_original_language.
    DATA:
      lv_iso_language      TYPE i18_a_langiso2,
      lv_original_language TYPE sy-langu.


    lv_iso_language = co_ajson->get_string( '/header/originalLanguage' ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
      EXPORTING
        input  = lv_iso_language
      IMPORTING
        output = lv_original_language.

    co_ajson->set_string( iv_path = '/header/originalLanguage'
                          iv_val  = lv_original_language ).
  ENDMETHOD.

ENDCLASS.
