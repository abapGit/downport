CLASS zcl_abapgit_gui_page_db DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_gui_page
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      RAISING zcx_abapgit_exception.

    METHODS zif_abapgit_gui_event_handler~on_event
        REDEFINITION .
  PROTECTED SECTION.

    METHODS render_content
        REDEFINITION .
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_action,
        delete TYPE string VALUE 'delete',
      END OF c_action .

    CLASS-METHODS delete
      IMPORTING
        !is_key TYPE zif_abapgit_persistence=>ty_content
      RAISING
        zcx_abapgit_exception.
    METHODS explain_content
      IMPORTING
        !is_data       TYPE zif_abapgit_persistence=>ty_content
      RETURNING
        VALUE(rv_text) TYPE string
      RAISING
        zcx_abapgit_exception .
ENDCLASS.



CLASS ZCL_ABAPGIT_GUI_PAGE_DB IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    ms_control-page_title = 'Database Utility'.
  ENDMETHOD.


  METHOD delete.

    DATA: lv_answer TYPE c LENGTH 1.

    ASSERT is_key-type IS NOT INITIAL.

    lv_answer = zcl_abapgit_ui_factory=>get_popups( )->popup_to_confirm(
      iv_titlebar              = 'Warning'
      iv_text_question         = 'Delete?'
      iv_text_button_1         = 'Ok'
      iv_icon_button_1         = 'ICON_DELETE'
      iv_text_button_2         = 'Cancel'
      iv_icon_button_2         = 'ICON_CANCEL'
      iv_default_button        = '2'
      iv_display_cancel_button = abap_false ).

    IF lv_answer = '2'.
      RAISE EXCEPTION TYPE zcx_abapgit_cancel.
    ENDIF.

    zcl_abapgit_persistence_db=>get_instance( )->delete(
      iv_type  = is_key-type
      iv_value = is_key-value ).

    COMMIT WORK.

  ENDMETHOD.


  METHOD explain_content.

    DATA: ls_result TYPE match_result,
          ls_match  TYPE submatch_result,
          lv_cnt    TYPE i.


    CASE is_data-type.
      WHEN 'REPO'.
        FIND FIRST OCCURRENCE OF REGEX '<url>(.*)</url>'
          IN is_data-data_str IGNORING CASE RESULTS ls_result.
        READ TABLE ls_result-submatches INTO ls_match INDEX 1.
        IF sy-subrc IS INITIAL.
          rv_text = is_data-data_str+ls_match-offset(ls_match-length).
        ENDIF.

        FIND FIRST OCCURRENCE OF REGEX '<OFFLINE/>'
          IN is_data-data_str IGNORING CASE MATCH COUNT lv_cnt.
        IF lv_cnt > 0.
          rv_text = |<strong>On-line</strong>, Name: <strong>{
                    zcl_abapgit_url=>name( rv_text ) }</strong>|.
        ELSE.
          rv_text = |Off-line, Name: <strong>{ rv_text }</strong>|.
        ENDIF.

      WHEN 'BACKGROUND'.
        FIND FIRST OCCURRENCE OF REGEX '<method>(.*)</method>'
          IN is_data-data_str IGNORING CASE RESULTS ls_result.
        READ TABLE ls_result-submatches INTO ls_match INDEX 1.
        IF sy-subrc IS NOT INITIAL.
          RETURN.
        ENDIF.
        rv_text = |Method: { is_data-data_str+ls_match-offset(ls_match-length) }, |
               && |Repository: { zcl_abapgit_repo_srv=>get_instance( )->get( is_data-value )->get_name( ) }|.

      WHEN 'USER'.
        rv_text = '-'. " No additional explanation for user
      WHEN 'SETTINGS'.
        rv_text = '-'.
      WHEN OTHERS.
        IF strlen( is_data-data_str ) >= 250.
          rv_text = is_data-data_str(250).
        ELSE.
          rv_text = is_data-data_str.
        ENDIF.
        rv_text = escape( val    = rv_text
                          format = cl_abap_format=>e_html_attr ).
        rv_text = |<pre>{ rv_text }</pre>|.
    ENDCASE.
  ENDMETHOD.


  METHOD render_content.

    DATA: lt_data    TYPE zif_abapgit_persistence=>ty_contents,
          lv_action  TYPE string,
          lv_trclass TYPE string,
          lo_toolbar TYPE REF TO zcl_abapgit_html_toolbar.

    FIELD-SYMBOLS: <ls_data> LIKE LINE OF lt_data.


    lt_data = zcl_abapgit_persistence_db=>get_instance( )->list( ).

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.

    ri_html->add( '<div class="db_list">' ).
    ri_html->add( '<table class="db_tab">' ).

    " Header
    ri_html->add( '<thead>' ).
    ri_html->add( '<tr>' ).
    ri_html->add( '<th>Type</th>' ).
    ri_html->add( '<th>Key</th>' ).
    ri_html->add( '<th>Data</th>' ).
    ri_html->add( '<th></th>' ).
    ri_html->add( '</tr>' ).
    ri_html->add( '</thead>' ).
    ri_html->add( '<tbody>' ).

    " Lines
    LOOP AT lt_data ASSIGNING <ls_data>.
      CLEAR lv_trclass.
      IF sy-tabix = 1.
        lv_trclass = ' class="firstrow"'.
      ENDIF.

      lv_action  = zcl_abapgit_html_action_utils=>dbkey_encode( <ls_data> ).

      CREATE OBJECT lo_toolbar.
      lo_toolbar->add( iv_txt = 'Display'
                       iv_act = |{ zif_abapgit_definitions=>c_action-db_display }?{ lv_action }| ).
      lo_toolbar->add( iv_txt = 'Edit'
                       iv_act = |{ zif_abapgit_definitions=>c_action-db_edit }?{ lv_action }| ).
      lo_toolbar->add( iv_txt = 'Delete'
                       iv_act = |{ c_action-delete }?{ lv_action }| ).

      ri_html->add( |<tr{ lv_trclass }>| ).
      ri_html->add( |<td>{ <ls_data>-type }</td>| ).
      ri_html->add( |<td>{ <ls_data>-value }</td>| ).
      ri_html->add( |<td class="data">{ explain_content( <ls_data> ) }</td>| ).
      ri_html->add( '<td>' ).
      ri_html->add( lo_toolbar->render( ) ).
      ri_html->add( '</td>' ).
      ri_html->add( '</tr>' ).
    ENDLOOP.

    ri_html->add( '</tbody>' ).
    ri_html->add( '</table>' ).
    ri_html->add( '</div>' ).

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.

    DATA ls_db TYPE zif_abapgit_persistence=>ty_content.
    DATA lo_query TYPE REF TO zcl_abapgit_string_map.

    lo_query = ii_event->query( ).
    CASE ii_event->mv_action.
      WHEN c_action-delete.
        lo_query->to_abap( CHANGING cs_container = ls_db ).
        delete( ls_db ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN OTHERS.
        rs_handled = super->zif_abapgit_gui_event_handler~on_event( ii_event ).
    ENDCASE.

  ENDMETHOD.
ENDCLASS.
