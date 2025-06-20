CLASS zcl_abapgit_objects_files DEFINITION
  PUBLIC
  CREATE PRIVATE.

  PUBLIC SECTION.

    CLASS-METHODS new
      IMPORTING
        !is_item        TYPE zif_abapgit_definitions=>ty_item
        !iv_path        TYPE string OPTIONAL
      RETURNING
        VALUE(ro_files) TYPE REF TO zcl_abapgit_objects_files.
    METHODS constructor
      IMPORTING
        !is_item TYPE zif_abapgit_definitions=>ty_item
        !iv_path TYPE string OPTIONAL .
    METHODS add_string
      IMPORTING
        !iv_extra  TYPE clike OPTIONAL
        !iv_ext    TYPE string
        !iv_string TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS read_string
      IMPORTING
        !iv_extra        TYPE clike OPTIONAL
        !iv_ext          TYPE string
      RETURNING
        VALUE(rv_string) TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS add_xml
      IMPORTING
        !iv_extra     TYPE clike OPTIONAL
        !ii_xml       TYPE REF TO zif_abapgit_xml_output
        !iv_normalize TYPE abap_bool DEFAULT abap_true
        !is_metadata  TYPE zif_abapgit_definitions=>ty_metadata OPTIONAL
      RAISING
        zcx_abapgit_exception .
    METHODS read_xml
      IMPORTING
        !iv_extra     TYPE clike OPTIONAL
      RETURNING
        VALUE(ri_xml) TYPE REF TO zif_abapgit_xml_input
      RAISING
        zcx_abapgit_exception .
    METHODS read_abap
      IMPORTING
        !iv_extra      TYPE clike OPTIONAL
        !iv_error      TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rt_abap) TYPE abaptxt255_tab
      RAISING
        zcx_abapgit_exception .
    METHODS add_abap
      IMPORTING
        !iv_extra TYPE clike OPTIONAL
        !it_abap  TYPE STANDARD TABLE
      RAISING
        zcx_abapgit_exception .
    METHODS add
      IMPORTING
        !is_file TYPE zif_abapgit_git_definitions=>ty_file .
    METHODS add_raw
      IMPORTING
        !iv_extra TYPE clike OPTIONAL
        !iv_ext   TYPE string
        !iv_data  TYPE xstring.
    METHODS read_raw
      IMPORTING
        !iv_extra      TYPE clike OPTIONAL
        !iv_ext        TYPE string
      RETURNING
        VALUE(rv_data) TYPE xstring
      RAISING
        zcx_abapgit_exception .
    METHODS get_files
      RETURNING
        VALUE(rt_files) TYPE zif_abapgit_git_definitions=>ty_files_tt .
    METHODS set_files
      IMPORTING
        !it_files TYPE zif_abapgit_git_definitions=>ty_files_tt .
    METHODS get_accessed_files
      RETURNING
        VALUE(rt_files) TYPE zif_abapgit_git_definitions=>ty_file_signatures_tt .
    METHODS contains_file
      IMPORTING
        !iv_extra         TYPE clike OPTIONAL
        !iv_ext           TYPE string
      RETURNING
        VALUE(rv_present) TYPE abap_bool .
    METHODS get_file_pattern
      RETURNING
        VALUE(rv_pattern) TYPE string .
    METHODS is_json_metadata
      RETURNING
        VALUE(rv_result) TYPE abap_bool.
    METHODS add_i18n_file
      IMPORTING
        !ii_i18n_file TYPE REF TO zif_abapgit_i18n_file
      RAISING
        zcx_abapgit_exception .
    METHODS read_i18n_files
      RETURNING
        VALUE(rt_i18n_files) TYPE zif_abapgit_i18n_file=>ty_table_of
      RAISING
        zcx_abapgit_exception .

  PROTECTED SECTION.

    METHODS read_file
      IMPORTING
        !iv_filename   TYPE string
        !iv_error      TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_data) TYPE xstring
      RAISING
        zcx_abapgit_exception .
  PRIVATE SECTION.

    DATA ms_item TYPE zif_abapgit_definitions=>ty_item .
    DATA mt_accessed_files TYPE zif_abapgit_git_definitions=>ty_file_signatures_tt .
    DATA mt_files TYPE zif_abapgit_git_definitions=>ty_files_tt .
    DATA mv_path TYPE string .

    METHODS mark_accessed
      IMPORTING
        !iv_path TYPE zif_abapgit_git_definitions=>ty_file-path
        !iv_file TYPE zif_abapgit_git_definitions=>ty_file-filename
        !iv_sha1 TYPE zif_abapgit_git_definitions=>ty_file-sha1.

ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECTS_FILES IMPLEMENTATION.


  METHOD add.
    APPEND is_file TO mt_files.
  ENDMETHOD.


  METHOD add_abap.

    DATA: lv_source TYPE string,
          ls_file   TYPE zif_abapgit_git_definitions=>ty_file.


    CONCATENATE LINES OF it_abap INTO lv_source SEPARATED BY cl_abap_char_utilities=>newline.
* when editing files via eg. GitHub web interface it adds a newline at end of file
    lv_source = lv_source && cl_abap_char_utilities=>newline.

    ls_file-path = '/'.
    ls_file-filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = 'abap' ).
    ls_file-data = zcl_abapgit_convert=>string_to_xstring_utf8( lv_source ).

    APPEND ls_file TO mt_files.

  ENDMETHOD.


  METHOD add_i18n_file.

    DATA ls_file TYPE zif_abapgit_git_definitions=>ty_file.

    ls_file-data = ii_i18n_file->render( ).
    IF ls_file-data IS INITIAL.
      RETURN. " Don't add empty files
    ENDIF.

    ls_file-path     = '/'.
    ls_file-filename = zcl_abapgit_filename_logic=>object_to_i18n_file(
      is_item  = ms_item
      iv_lang_suffix = ii_i18n_file->lang_suffix( )
      iv_ext   = ii_i18n_file->ext( ) ).

    APPEND ls_file TO mt_files.

  ENDMETHOD.


  METHOD add_raw.

    DATA: ls_file TYPE zif_abapgit_git_definitions=>ty_file.

    ls_file-path     = '/'.
    ls_file-data     = iv_data.
    ls_file-filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = iv_ext ).

    APPEND ls_file TO mt_files.

  ENDMETHOD.


  METHOD add_string.

    DATA: ls_file TYPE zif_abapgit_git_definitions=>ty_file.

    ls_file-path = '/'.
    ls_file-filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = iv_ext ).
    ls_file-data = zcl_abapgit_convert=>string_to_xstring_utf8( iv_string ).

    APPEND ls_file TO mt_files.

  ENDMETHOD.


  METHOD add_xml.

    DATA: lv_xml  TYPE string,
          ls_file TYPE zif_abapgit_git_definitions=>ty_file.

    lv_xml = ii_xml->render( iv_normalize = iv_normalize
                             is_metadata = is_metadata ).
    ls_file-path = '/'.

    ls_file-filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = 'xml' ).

    REPLACE FIRST OCCURRENCE
      OF REGEX '<\?xml version="1\.0" encoding="[\w-]+"\?>'
      IN lv_xml
      WITH '<?xml version="1.0" encoding="utf-8"?>'.
    ASSERT sy-subrc = 0.

    ls_file-data = zcl_abapgit_convert=>string_to_xstring_utf8_bom( lv_xml ).

    APPEND ls_file TO mt_files.
  ENDMETHOD.


  METHOD constructor.
    ms_item = is_item.
    mv_path = iv_path.
  ENDMETHOD.


  METHOD contains_file.
    DATA: lv_filename TYPE string.

    lv_filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = iv_ext ).

    IF mv_path IS NOT INITIAL.
      READ TABLE mt_files TRANSPORTING NO FIELDS
          WITH KEY file_path
          COMPONENTS path     = mv_path
                     filename = lv_filename.
    ELSE.
      READ TABLE mt_files TRANSPORTING NO FIELDS
          WITH KEY file
          COMPONENTS filename = lv_filename.
    ENDIF.

    IF sy-subrc = 0.
      rv_present = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD get_accessed_files.
    rt_files = mt_accessed_files.
  ENDMETHOD.


  METHOD get_files.
    rt_files = mt_files.
  ENDMETHOD.


  METHOD get_file_pattern.
    rv_pattern = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_ext   = '*' ).
    " Escape special characters for use with 'covers pattern' (CP)
    REPLACE ALL OCCURRENCES OF '#' IN rv_pattern WITH '##'.
    REPLACE ALL OCCURRENCES OF '+' IN rv_pattern WITH '#+'.
  ENDMETHOD.


  METHOD is_json_metadata.

    DATA lv_pattern TYPE string.

    FIELD-SYMBOLS <ls_file> LIKE LINE OF mt_files.

    lv_pattern = |*.{ to_lower( ms_item-obj_type ) }.json|.

    LOOP AT mt_files ASSIGNING <ls_file> WHERE filename CP lv_pattern.
      rv_result = abap_true.
      EXIT.
    ENDLOOP.

  ENDMETHOD.


  METHOD mark_accessed.

    FIELD-SYMBOLS <ls_accessed> LIKE LINE OF mt_accessed_files.

    READ TABLE mt_accessed_files TRANSPORTING NO FIELDS
      WITH KEY path = iv_path filename = iv_file.
    IF sy-subrc > 0. " Not found ? -> Add
      APPEND INITIAL LINE TO mt_accessed_files ASSIGNING <ls_accessed>.
      <ls_accessed>-path     = iv_path.
      <ls_accessed>-filename = iv_file.
      <ls_accessed>-sha1     = iv_sha1.
    ENDIF.

  ENDMETHOD.


  METHOD new.
    CREATE OBJECT ro_files EXPORTING is_item = is_item
                                     iv_path = iv_path.
  ENDMETHOD.


  METHOD read_abap.

    DATA: lv_filename TYPE string,
          lv_data     TYPE xstring,
          lv_abap     TYPE string.


    lv_filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = 'abap' ).

    lv_data = read_file( iv_filename = lv_filename
                         iv_error    = iv_error ).

    IF lv_data IS INITIAL. " Post-handling of iv_error = false
      RETURN.
    ENDIF.

    lv_abap = zcl_abapgit_convert=>xstring_to_string_utf8( lv_data ).

    SPLIT lv_abap AT cl_abap_char_utilities=>newline INTO TABLE rt_abap.

  ENDMETHOD.


  METHOD read_file.

    FIELD-SYMBOLS <ls_file>     LIKE LINE OF mt_files.

    IF mv_path IS NOT INITIAL.
      READ TABLE mt_files ASSIGNING <ls_file>
          WITH KEY file_path
          COMPONENTS path     = mv_path
                     filename = iv_filename.
    ELSE.
      READ TABLE mt_files ASSIGNING <ls_file>
          WITH KEY file
          COMPONENTS filename = iv_filename.
    ENDIF.

    IF sy-subrc <> 0.
      IF iv_error = abap_true.
        zcx_abapgit_exception=>raise( |File not found: { iv_filename }| ).
      ELSE.
        RETURN.
      ENDIF.
    ENDIF.

    " Update access table
    mark_accessed(
      iv_path = <ls_file>-path
      iv_file = <ls_file>-filename
      iv_sha1 = <ls_file>-sha1 ).

    rv_data = <ls_file>-data.

  ENDMETHOD.


  METHOD read_i18n_files.

    DATA:
      lv_lang       TYPE laiso,
      lv_ext        TYPE string,
      lo_po         TYPE REF TO zcl_abapgit_po_file,
      lo_properties TYPE REF TO zcl_abapgit_properties_file.

    FIELD-SYMBOLS <ls_file> LIKE LINE OF mt_files.

    LOOP AT mt_files ASSIGNING <ls_file>.

      CHECK find( val = <ls_file>-filename
                  sub = '.i18n.' ) > 0. " Only i18n files are relevant

      zcl_abapgit_filename_logic=>i18n_file_to_object(
        EXPORTING
          iv_path     = <ls_file>-path
          iv_filename = <ls_file>-filename
        IMPORTING
          ev_lang     = lv_lang
          ev_ext      = lv_ext ).

      CASE lv_ext.
        WHEN 'po'.
          CREATE OBJECT lo_po EXPORTING iv_lang = lv_lang.
          lo_po->parse( <ls_file>-data ).
          APPEND lo_po TO rt_i18n_files.
        WHEN 'properties'.
          CREATE OBJECT lo_properties EXPORTING iv_lang = lv_lang.
          lo_properties->parse( <ls_file>-data ).
          APPEND lo_properties TO rt_i18n_files.
        WHEN OTHERS.
          CONTINUE. " Unsupported i18n file type
      ENDCASE.

      mark_accessed(
        iv_path = <ls_file>-path
        iv_file = <ls_file>-filename
        iv_sha1 = <ls_file>-sha1 ).

    ENDLOOP.

  ENDMETHOD.


  METHOD read_raw.

    DATA: lv_filename TYPE string.

    lv_filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = iv_ext ).

    rv_data = read_file( lv_filename ).

  ENDMETHOD.


  METHOD read_string.

    DATA: lv_filename TYPE string,
          lv_data     TYPE xstring.

    lv_filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = iv_ext ).

    lv_data = read_file( lv_filename ).

    rv_string = zcl_abapgit_convert=>xstring_to_string_utf8( lv_data ).

  ENDMETHOD.


  METHOD read_xml.

    DATA: lv_filename TYPE string,
          lv_data     TYPE xstring,
          lv_xml      TYPE string.

    lv_filename = zcl_abapgit_filename_logic=>object_to_file(
      is_item  = ms_item
      iv_extra = iv_extra
      iv_ext   = 'xml' ).

    lv_data = read_file( lv_filename ).

    lv_xml = zcl_abapgit_convert=>xstring_to_string_utf8( lv_data ).

    CREATE OBJECT ri_xml TYPE zcl_abapgit_xml_input EXPORTING iv_xml = lv_xml
                                                              iv_filename = lv_filename.

  ENDMETHOD.


  METHOD set_files.

    FIELD-SYMBOLS: <ls_file> LIKE LINE OF it_files.

    CLEAR mt_files.

    " Set only files matching the pattern for this object
    " If a path has been defined in the constructor, then the path has to match, too
    LOOP AT it_files ASSIGNING <ls_file> WHERE filename CP get_file_pattern( ).
      IF mv_path IS INITIAL.
        INSERT <ls_file> INTO TABLE mt_files.
      ELSEIF mv_path = <ls_file>-path.
        INSERT <ls_file> INTO TABLE mt_files.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
