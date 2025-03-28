CLASS zcl_abapgit_object_iwpr DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_objects_super
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_object .
  PROTECTED SECTION.

    METHODS get_generic
      RETURNING
        VALUE(ro_generic) TYPE REF TO zcl_abapgit_objects_generic
      RAISING
        zcx_abapgit_exception .
  PRIVATE SECTION.
    METHODS get_field_rules
      RETURNING
        VALUE(ro_result) TYPE REF TO zif_abapgit_field_rules.
ENDCLASS.



CLASS zcl_abapgit_object_iwpr IMPLEMENTATION.


  METHOD get_field_rules.
    ro_result = zcl_abapgit_field_rules=>create( ).
    ro_result->add(
      iv_table     = '/IWBEP/I_SBD_GA'
      iv_field     = 'CREATION_USER_ID'
      iv_fill_rule = zif_abapgit_field_rules=>c_fill_rule-user
    )->add(
      iv_table     = '/IWBEP/I_SBD_GA'
      iv_field     = 'CREATION_TIME'
      iv_fill_rule = zif_abapgit_field_rules=>c_fill_rule-timestamp
    )->add(
      iv_table     = '/IWBEP/I_SBD_GA'
      iv_field     = 'LAST_CHG_USER_ID'
      iv_fill_rule = zif_abapgit_field_rules=>c_fill_rule-user
    )->add(
      iv_table     = '/IWBEP/I_SBD_GA'
      iv_field     = 'LAST_CHG_TIME'
      iv_fill_rule = zif_abapgit_field_rules=>c_fill_rule-timestamp ).
  ENDMETHOD.


  METHOD get_generic.

    CREATE OBJECT ro_generic EXPORTING io_field_rules = get_field_rules( )
                                       is_item = ms_item
                                       iv_language = mv_language.

  ENDMETHOD.


  METHOD zif_abapgit_object~changed_by.

    SELECT SINGLE last_chg_user_id FROM ('/IWBEP/I_SBD_PR') INTO rv_user
      WHERE project = ms_item-obj_name.
    IF sy-subrc <> 0.
      rv_user = c_user_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    get_generic( )->delete( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.

    get_generic( )->deserialize(
      iv_package = iv_package
      io_xml     = io_xml ).

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.

    rv_bool = get_generic( )->exists( ).

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

    DATA lv_prog TYPE progname.

    lv_prog = '/IWBEP/R_SBUI_SERVICE_BUILDER'.

    SUBMIT (lv_prog)
      WITH i_prname = ms_item-obj_name
      AND RETURN.

    rv_exit = abap_true.

  ENDMETHOD.


  METHOD zif_abapgit_object~map_filename_to_object.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~map_object_to_filename.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.

    get_generic( )->serialize( io_xml ).

  ENDMETHOD.
ENDCLASS.
