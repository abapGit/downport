CLASS zcl_abapgit_object_cmpt DEFINITION PUBLIC INHERITING FROM zcl_abapgit_objects_super FINAL.

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !is_item        TYPE zif_abapgit_definitions=>ty_item
        !iv_language    TYPE spras
        !io_files       TYPE REF TO zcl_abapgit_objects_files OPTIONAL
        !io_i18n_params TYPE REF TO zcl_abapgit_i18n_params OPTIONAL
      RAISING
        zcx_abapgit_type_not_supported.

    INTERFACES zif_abapgit_object.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: mo_cmp_db TYPE REF TO object,
          mv_name   TYPE c LENGTH 30.

ENDCLASS.



CLASS zcl_abapgit_object_cmpt IMPLEMENTATION.


  METHOD constructor.

    super->constructor(
      is_item        = is_item
      iv_language    = iv_language
      io_files       = io_files
      io_i18n_params = io_i18n_params ).

    TRY.
        CALL METHOD ('CL_CMP_TEMPLATE')=>('S_GET_DB_ACCESS')
          RECEIVING
            r_ref_db_access = mo_cmp_db.

      CATCH cx_root.
        RAISE EXCEPTION TYPE zcx_abapgit_type_not_supported EXPORTING obj_type = is_item-obj_type.
    ENDTRY.

    mv_name = ms_item-obj_name.

  ENDMETHOD.


  METHOD zif_abapgit_object~changed_by.

    DATA: lo_cmp_template TYPE REF TO object.

    CALL METHOD ('CL_CMP_TEMPLATE')=>('S_CREATE_FROM_DB')
      EXPORTING
        i_name         = mv_name
        i_version      = 'A'
      RECEIVING
        r_ref_template = lo_cmp_template.

    CALL METHOD lo_cmp_template->('IF_CMP_TEMPLATE_EDIT~GET_CHANGE_USER')
      RECEIVING
        r_user = rv_user.

  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    DATA: lv_deleted TYPE abap_bool.

    CALL METHOD mo_cmp_db->('IF_CMP_TEMPLATE_DB~DELETE_TEMPLATE')
      EXPORTING
        i_name        = mv_name
        i_version     = 'A'
        i_flg_header  = abap_true
        i_flg_lines   = abap_true
      RECEIVING
        r_flg_deleted = lv_deleted.

    IF lv_deleted = abap_false.
      zcx_abapgit_exception=>raise( |Error deleting CMPT { ms_item-obj_name }| ).
    ENDIF.

    corr_insert( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.

    DATA: lr_template TYPE REF TO data.
    FIELD-SYMBOLS: <lg_template> TYPE any,
                   <lg_header>   TYPE any,
                   <lg_field>    TYPE any.

    CREATE DATA lr_template TYPE ('IF_CMP_TEMPLATE_DB=>TYP_TEMPLATE').
    ASSIGN lr_template->* TO <lg_template>.

    io_xml->read(
      EXPORTING
        iv_name = 'CMPT'
      CHANGING
        cg_data = <lg_template> ).

    ASSIGN COMPONENT 'STR_HEADER' OF STRUCTURE <lg_template> TO <lg_header>.
    IF sy-subrc = 0.
      ASSIGN COMPONENT 'NAME' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        <lg_field> = ms_item-obj_name.
      ENDIF.
      ASSIGN COMPONENT 'VERSION' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        <lg_field> = 'A'.
      ENDIF.
    ENDIF.

    CALL METHOD mo_cmp_db->('IF_CMP_TEMPLATE_DB~SAVE_TEMPLATE')
      EXPORTING
        i_template_db = <lg_template>
        i_flg_header  = abap_true
        i_flg_lines   = abap_true.

    corr_insert( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.

    CALL METHOD ('CL_CMP_TEMPLATE')=>('S_TEMPLATE_EXISTS')
      EXPORTING
        i_name       = mv_name
        i_version    = 'A'
      RECEIVING
        r_flg_exists = rv_bool.
    IF rv_bool = abap_false.
      CALL METHOD ('CL_CMP_TEMPLATE')=>('S_TEMPLATE_EXISTS')
        EXPORTING
          i_name       = mv_name
          i_version    = 'I'
        RECEIVING
          r_flg_exists = rv_bool.
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_object~get_comparator.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_order.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_steps.
    APPEND zif_abapgit_object=>gc_step_id-abap TO rt_steps.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_active.
    rv_active = is_active( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_locked.

    rv_is_locked = abap_false.

  ENDMETHOD.


  METHOD zif_abapgit_object~jump.
    " Covered by ZCL_ABAPGIT_OBJECTS=>JUMP
  ENDMETHOD.


  METHOD zif_abapgit_object~map_filename_to_object.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~map_object_to_filename.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.

    DATA: lr_template TYPE REF TO data.
    FIELD-SYMBOLS: <lg_template> TYPE any,
                   <lg_header>   TYPE any,
                   <lg_field>    TYPE any.

    CREATE DATA lr_template TYPE ('IF_CMP_TEMPLATE_DB=>TYP_TEMPLATE').
    ASSIGN lr_template->* TO <lg_template>.

    CALL METHOD mo_cmp_db->('IF_CMP_TEMPLATE_DB~READ_TEMPLATE')
      EXPORTING
        i_name     = |{ ms_item-obj_name }|
        i_version  = 'A'
      RECEIVING
        r_template = <lg_template>.

    ASSIGN COMPONENT 'STR_HEADER' OF STRUCTURE <lg_template> TO <lg_header>.
    IF sy-subrc = 0.
      ASSIGN COMPONENT 'NAME' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        CLEAR <lg_field>.
      ENDIF.
      ASSIGN COMPONENT 'VERSION' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        CLEAR <lg_field>.
      ENDIF.
      ASSIGN COMPONENT 'CHANGED_ON' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        CLEAR <lg_field>.
      ENDIF.
      ASSIGN COMPONENT 'CHANGED_BY' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        CLEAR <lg_field>.
      ENDIF.
      ASSIGN COMPONENT 'CHANGED_TS' OF STRUCTURE <lg_header> TO <lg_field>.
      IF sy-subrc = 0.
        CLEAR <lg_field>.
      ENDIF.
    ENDIF.

    io_xml->add( iv_name = 'CMPT'
                 ig_data = <lg_template> ).

  ENDMETHOD.
ENDCLASS.
