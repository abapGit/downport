CLASS zcl_abapgit_background DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_method,
             class       TYPE seoclsname,
             description TYPE string,
           END OF ty_method.

    TYPES: ty_methods TYPE SORTED TABLE OF ty_method WITH UNIQUE KEY class.

    CLASS-METHODS run
      RAISING
        zcx_abapgit_exception .

    CLASS-METHODS list_methods
      RETURNING VALUE(rt_methods) TYPE ty_methods.

    CLASS-METHODS enqueue
      RAISING
        zcx_abapgit_exception.

    CLASS-METHODS dequeue.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS c_enq_type TYPE c LENGTH 12 VALUE 'BACKGROUND'.
ENDCLASS.



CLASS zcl_abapgit_background IMPLEMENTATION.


  METHOD dequeue.
    CALL FUNCTION 'DEQUEUE_EZABAPGIT'
      EXPORTING
        type = c_enq_type.
  ENDMETHOD.


  METHOD enqueue.
    CALL FUNCTION 'ENQUEUE_EZABAPGIT'
      EXPORTING
        mode_zabapgit  = 'E'
        type           = c_enq_type
        _scope         = '3'
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.
  ENDMETHOD.


  METHOD list_methods.

    DATA: ls_method       LIKE LINE OF rt_methods,
          ls_key          TYPE seoclskey,
          lt_implementing TYPE seor_implementing_keys,
          ls_implementing LIKE LINE OF lt_implementing.

    FIELD-SYMBOLS: <ls_method> LIKE LINE OF rt_methods.


* in order to handle local classes in the compiled report
    ls_method-class = 'ZCL_ABAPGIT_BACKGROUND_PULL'.
    INSERT ls_method INTO TABLE rt_methods.
    ls_method-class = 'ZCL_ABAPGIT_BACKGROUND_PUSH_AU'.
    INSERT ls_method INTO TABLE rt_methods.
    ls_method-class = 'ZCL_ABAPGIT_BACKGROUND_PUSH_FI'.
    INSERT ls_method INTO TABLE rt_methods.

    ls_key-clsname = 'ZIF_ABAPGIT_BACKGROUND'.

    CALL FUNCTION 'SEO_INTERFACE_IMPLEM_GET_ALL'
      EXPORTING
        intkey       = ls_key
      IMPORTING
        impkeys      = lt_implementing
      EXCEPTIONS
        not_existing = 1
        OTHERS       = 2 ##FM_SUBRC_OK.
    LOOP AT lt_implementing INTO ls_implementing.
      ls_method-class = ls_implementing-clsname.
      INSERT ls_method INTO TABLE rt_methods.
    ENDLOOP.

    LOOP AT rt_methods ASSIGNING <ls_method>.
      CALL METHOD (<ls_method>-class)=>zif_abapgit_background~get_description
        RECEIVING
          rv_description = <ls_method>-description.
    ENDLOOP.

  ENDMETHOD.


  METHOD run.

    DATA: lo_per        TYPE REF TO zcl_abapgit_persist_background,
          lo_repo       TYPE REF TO zcl_abapgit_repo_online,
          lt_list       TYPE zcl_abapgit_persist_background=>ty_background_keys,
          li_background TYPE REF TO zif_abapgit_background,
          li_log        TYPE REF TO zif_abapgit_log,
          lx_error      TYPE REF TO zcx_abapgit_exception,
          lv_repo_name  TYPE string.

    FIELD-SYMBOLS: <ls_list> LIKE LINE OF lt_list.

    TRY.
        enqueue( ).
      CATCH zcx_abapgit_exception.
        WRITE: / 'Another instance of the program is already running'.
        RETURN.
    ENDTRY.

    lo_per = NEW #( ).
    lt_list = lo_per->list( ).

    WRITE: / 'Background mode'.

    LOOP AT lt_list ASSIGNING <ls_list>.
      li_log = NEW zcl_abapgit_log( ).

      TRY.
          lo_repo ?= zcl_abapgit_repo_srv=>get_instance( )->get( <ls_list>-key ).
          lv_repo_name = lo_repo->get_name( ).
          WRITE: / <ls_list>-method, lv_repo_name.

          zcl_abapgit_login_manager=>set(
            iv_uri      = lo_repo->get_url( )
            iv_username = <ls_list>-username
            iv_password = <ls_list>-password ).

          CREATE OBJECT li_background TYPE (<ls_list>-method).

          li_background->run(
            io_repo     = lo_repo
            ii_log      = li_log
            it_settings = <ls_list>-settings ).

          " Decrease memory usage for repository already processed (but keep log)
          lo_repo->refresh(
            iv_drop_cache = abap_true
            iv_drop_log   = abap_false ).

          " Clear auth buffer to allow different user/password per repository in background mode
          zcl_abapgit_login_manager=>clear( ).

        CATCH zcx_abapgit_exception INTO lx_error.
          li_log->add_exception( lx_error ).
      ENDTRY.

      zcl_abapgit_log_viewer=>write_log( li_log ).
    ENDLOOP.

    IF lines( lt_list ) = 0.
      WRITE: / 'Nothing configured'.
    ENDIF.

    dequeue( ).

  ENDMETHOD.
ENDCLASS.
