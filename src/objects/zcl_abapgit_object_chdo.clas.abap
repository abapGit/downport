CLASS zcl_abapgit_object_chdo DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_objects_super
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abapgit_object.

    METHODS constructor
      IMPORTING
        !is_item        TYPE zif_abapgit_definitions=>ty_item
        !iv_language    TYPE spras
        !io_files       TYPE REF TO zcl_abapgit_objects_files OPTIONAL
        !io_i18n_params TYPE REF TO zcl_abapgit_i18n_params OPTIONAL
      RAISING
        zcx_abapgit_exception.

  PROTECTED SECTION.

    METHODS after_import
      RAISING
        zcx_abapgit_exception .
    METHODS delete_tadir_cdnames
      IMPORTING
        !is_cdnames TYPE cdnames
      RAISING
        zcx_abapgit_exception .
    METHODS delete_tadir_tabl
      IMPORTING
        !is_tcdrs TYPE tcdrs
      RAISING
        zcx_abapgit_exception .
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_change_document,
             reports_generated TYPE SORTED TABLE OF tcdrps WITH UNIQUE KEY object reportname,
             objects           TYPE SORTED TABLE OF tcdobs WITH UNIQUE KEY object tabname,
             objects_text      TYPE SORTED TABLE OF tcdobts WITH UNIQUE KEY spras object,
           END OF ty_change_document.

    DATA: mv_object TYPE cdobjectcl.

ENDCLASS.



CLASS zcl_abapgit_object_chdo IMPLEMENTATION.


  METHOD after_import.

    TYPES temp1 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.
TYPES temp2 TYPE STANDARD TABLE OF sprot_u WITH DEFAULT KEY.
DATA: lt_cts_object_entry TYPE temp1,
          ls_cts_object_entry LIKE LINE OF lt_cts_object_entry,
          lt_errormsg         TYPE temp2.

    ls_cts_object_entry-pgmid    = 'R3TR'.
    ls_cts_object_entry-object   = ms_item-obj_type.
    ls_cts_object_entry-obj_name = ms_item-obj_name.
    INSERT ls_cts_object_entry INTO TABLE lt_cts_object_entry.

    CALL FUNCTION 'AFTER_IMP_CHDO'
      EXPORTING
        iv_tarclient  = sy-mandt
        iv_is_upgrade = abap_false
      TABLES
        tt_e071       = lt_cts_object_entry
        tt_errormsg   = lt_errormsg.

    LOOP AT lt_errormsg TRANSPORTING NO FIELDS WHERE severity = 'E' OR severity = 'A'.
      EXIT.
    ENDLOOP.

    IF sy-subrc = 0.
      zcx_abapgit_exception=>raise( 'Error from AFTER_IMP_CHDO' ).
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    super->constructor(
      is_item        = is_item
      iv_language    = iv_language
      io_files       = io_files
      io_i18n_params = io_i18n_params ).

    mv_object = is_item-obj_name.

  ENDMETHOD.


  METHOD delete_tadir_cdnames.

    IF is_cdnames-repnamec IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'PROG'
        iv_obj_name  = is_cdnames-repnamec ).
    ENDIF.

    IF is_cdnames-repnamet IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'PROG'
        iv_obj_name  = is_cdnames-repnamet ).
    ENDIF.

    IF is_cdnames-repnamefix IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'PROG'
        iv_obj_name  = is_cdnames-repnamefix ).
    ENDIF.

    IF is_cdnames-repnamevar IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'PROG'
        iv_obj_name  = is_cdnames-repnamevar ).
    ENDIF.

    IF is_cdnames-fgrp IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'FUGR'
        iv_obj_name  = is_cdnames-fgrp ).
    ENDIF.

  ENDMETHOD.


  METHOD delete_tadir_tabl.

    IF is_tcdrs-tabname IS NOT INITIAL.
      zcl_abapgit_factory=>get_tadir( )->delete_single(
        iv_object    = 'TABL'
        iv_obj_name  = is_tcdrs-tabname ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_object~changed_by.

    SELECT SINGLE updname INTO rv_user
      FROM tcdrp
      WHERE object = mv_object.
    IF sy-subrc <> 0.
      rv_user = c_user_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    TYPES temp3 TYPE STANDARD TABLE OF cdnames.
TYPES temp4 TYPE STANDARD TABLE OF tcdrs.
DATA: lt_cdnames TYPE temp3,
          ls_cdnames TYPE cdnames,
          lt_tcdrs   TYPE temp4,
          ls_tcdrs   TYPE tcdrs,
          lv_msg     TYPE symsgv.

    CALL FUNCTION 'CDNAMES_GET'
      EXPORTING
        iv_object        = mv_object
      TABLES
        it_tcdrs         = lt_tcdrs
        it_names         = lt_cdnames
      EXCEPTIONS
        object_space     = 1
        object_not_found = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.

    CALL FUNCTION 'CHDO_DELETE'
      EXPORTING
        iv_object        = mv_object
        iv_with_tadir    = abap_true
      EXCEPTIONS
        object_is_space  = 1
        object_not_found = 2
        other_error      = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
      lv_msg = mv_object.
      zcx_abapgit_exception=>raise_t100( iv_msgid = 'CD'
                                         iv_msgno = '869'
                                         iv_msgv1 = lv_msg ).
    ENDIF.

    LOOP AT lt_cdnames INTO ls_cdnames.
      delete_tadir_cdnames( ls_cdnames ).
    ENDLOOP.

    LOOP AT lt_tcdrs INTO ls_tcdrs.
      delete_tadir_tabl( ls_tcdrs ).
    ENDLOOP.

    corr_insert( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.

    DATA: ls_change_object TYPE ty_change_document.
    FIELD-SYMBOLS: <ls_report_generated> LIKE LINE OF ls_change_object-reports_generated.

    io_xml->read( EXPORTING iv_name = 'CHDO'
                  CHANGING  cg_data = ls_change_object ).

    DELETE FROM tcdobs  WHERE object = mv_object.
    DELETE FROM tcdobts WHERE object = mv_object.
    DELETE FROM tcdrps  WHERE object = mv_object.

    LOOP AT ls_change_object-reports_generated ASSIGNING <ls_report_generated>.
      <ls_report_generated>-devclass = iv_package.
    ENDLOOP.

    INSERT tcdobs  FROM TABLE ls_change_object-objects.
    INSERT tcdobts FROM TABLE ls_change_object-objects_text.
    INSERT tcdrps  FROM TABLE ls_change_object-reports_generated.

    tadir_insert( iv_package ).

    after_import( ).

    corr_insert( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.

    SELECT COUNT(*)
      FROM tcdrp
      WHERE object = mv_object.

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( sy-subrc = 0 ).
    rv_bool = temp1.

  ENDMETHOD.


  METHOD zif_abapgit_object~get_comparator.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_order.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_steps.
    APPEND zif_abapgit_object=>gc_step_id-abap TO rt_steps.
    APPEND zif_abapgit_object=>gc_step_id-lxe TO rt_steps.
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

    TYPES temp5 TYPE STANDARD TABLE OF bdcdata.
DATA: lt_bdcdata TYPE temp5,
          ls_bdcdata LIKE LINE OF lt_bdcdata.

    CLEAR: ls_bdcdata.
    ls_bdcdata-program  = 'SAPMSCDO_NEW'.
    ls_bdcdata-dynpro   = '0100'.
    ls_bdcdata-dynbegin = abap_true.
    APPEND ls_bdcdata TO lt_bdcdata.

    CLEAR: ls_bdcdata.
    ls_bdcdata-fnam = 'TCDOB-OBJECT'.
    ls_bdcdata-fval = mv_object.
    APPEND ls_bdcdata TO lt_bdcdata.

    CLEAR: ls_bdcdata.
    ls_bdcdata-fnam = 'BDC_OKCODE'.
    ls_bdcdata-fval = '=DISP'.
    APPEND ls_bdcdata TO lt_bdcdata.

    zcl_abapgit_objects_factory=>get_gui_jumper( )->jump_batch_input(
      iv_tcode   = 'SCDO'
      it_bdcdata = lt_bdcdata ).

    rv_exit = abap_true.

  ENDMETHOD.


  METHOD zif_abapgit_object~map_filename_to_object.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~map_object_to_filename.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.

    TYPES temp6 TYPE STANDARD TABLE OF tcdrp.
TYPES temp5 TYPE STANDARD TABLE OF tcdob.
TYPES temp1 TYPE STANDARD TABLE OF tcdobt.
DATA: ls_change_object TYPE ty_change_document,
          lt_tcdrp         TYPE temp6,
          lt_tcdob         TYPE temp5,
          lt_tcdobt        TYPE temp1,
          BEGIN OF ls_nulldatetime, " hack ro reset fields when they exist without syntax errors when they don't
            udate TYPE sy-datum,
            utime TYPE sy-uzeit,
          END OF ls_nulldatetime.

    FIELD-SYMBOLS: <ls_reports_generated> LIKE LINE OF ls_change_object-reports_generated,
                   <ls_objects>           LIKE LINE OF ls_change_object-objects,
                   <ls_objects_text>      LIKE LINE OF ls_change_object-objects_text.

    CALL FUNCTION 'CDNAMES_GET'
      EXPORTING
        iv_object        = mv_object
      TABLES
        it_tcdrp         = lt_tcdrp
        it_tcdob         = lt_tcdob
        it_tcdobt        = lt_tcdobt
      EXCEPTIONS
        object_space     = 1
        object_not_found = 2
        OTHERS           = 3.
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.

    ls_change_object-reports_generated = lt_tcdrp.
    ls_change_object-objects           = lt_tcdob.
    ls_change_object-objects_text      = lt_tcdobt.

    " At import, when CHDO is generated date & time change, so always detects changes for this fields
    LOOP AT ls_change_object-reports_generated ASSIGNING <ls_reports_generated>.
      CLEAR: <ls_reports_generated>-datum, <ls_reports_generated>-uzeit,
             <ls_reports_generated>-author, <ls_reports_generated>-updname,
             <ls_reports_generated>-devclass.
    ENDLOOP.

    LOOP AT ls_change_object-objects ASSIGNING <ls_objects>.
      MOVE-CORRESPONDING ls_nulldatetime TO <ls_objects>. " reset date and time
    ENDLOOP.

    LOOP AT ls_change_object-objects_text ASSIGNING <ls_objects_text>.
      MOVE-CORRESPONDING ls_nulldatetime TO <ls_objects_text>. " reset date and time
    ENDLOOP.

    io_xml->add( iv_name = 'CHDO'
                 ig_data = ls_change_object ).

  ENDMETHOD.
ENDCLASS.
