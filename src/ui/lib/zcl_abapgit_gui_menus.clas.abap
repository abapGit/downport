CLASS zcl_abapgit_gui_menus DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS advanced
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

    CLASS-METHODS help
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

    CLASS-METHODS back
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

    CLASS-METHODS settings
      IMPORTING
        !iv_act        TYPE string
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

    CLASS-METHODS repo_settings
      IMPORTING
        !iv_key        TYPE zif_abapgit_persistence=>ty_repo-key
        !iv_act        TYPE string
      RETURNING
        VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.

    CLASS-METHODS experimental
      IMPORTING
        io_menu TYPE REF TO zcl_abapgit_html_toolbar.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_abapgit_gui_menus IMPLEMENTATION.


  METHOD advanced.

    ro_menu = zcl_abapgit_html_toolbar=>create( 'toolbar-advanced' ).

    ro_menu->add(
      iv_txt = 'Database Utility'
      iv_act = zif_abapgit_definitions=>c_action-go_db
    )->add(
      iv_txt = 'Package to ZIP'
      iv_act = zif_abapgit_definitions=>c_action-zip_package
    )->add(
      iv_txt = 'Transport to ZIP'
      iv_act = zif_abapgit_definitions=>c_action-zip_transport
    )->add(
      iv_txt = 'Object to Files'
      iv_act = zif_abapgit_definitions=>c_action-zip_object
    )->add(
      iv_txt = 'Debug Info'
      iv_act = zif_abapgit_definitions=>c_action-go_debuginfo ).

    IF zcl_abapgit_ui_factory=>get_frontend_services( )->is_sapgui_for_windows( ) = abap_true.
      ro_menu->add(
        iv_txt = 'Open IE DevTools'
        iv_act = zif_abapgit_definitions=>c_action-ie_devtools ).
    ENDIF.

  ENDMETHOD.


  METHOD back.

    ro_menu = zcl_abapgit_html_toolbar=>create( 'toolbar-back' ).

    ro_menu->add(
      iv_txt = 'Back'
      iv_act = zif_abapgit_definitions=>c_action-go_back ).

  ENDMETHOD.


  METHOD experimental.

    IF zcl_abapgit_persist_factory=>get_settings( )->read( )->get_experimental_features( ) IS NOT INITIAL.
      io_menu->add(
        iv_txt = zcl_abapgit_gui_buttons=>experimental( )
        iv_act = zif_abapgit_definitions=>c_action-go_settings ).
    ENDIF.

  ENDMETHOD.


  METHOD help.

    ro_menu = zcl_abapgit_html_toolbar=>create( 'toolbar-help' ).

    ro_menu->add(
      iv_txt = 'Tutorial'
      iv_act = zif_abapgit_definitions=>c_action-go_tutorial
    )->add(
      iv_txt = 'Documentation'
      iv_act = zif_abapgit_definitions=>c_action-documentation
    )->add(
      iv_txt = 'Explore'
      iv_act = zif_abapgit_definitions=>c_action-go_explore
    )->add(
      iv_txt = 'Changelog'
      iv_act = zif_abapgit_definitions=>c_action-changelog
    )->add(
      iv_txt = 'Hotkeys'
      iv_act = zif_abapgit_definitions=>c_action-show_hotkeys ).

  ENDMETHOD.


  METHOD repo_settings.

    ro_menu = zcl_abapgit_html_toolbar=>create( 'toolbar-repo-settings' ).

    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( iv_act = zif_abapgit_definitions=>c_action-repo_settings ).
    DATA temp2 TYPE xsdboolean.
    temp2 = boolc( iv_act = zif_abapgit_definitions=>c_action-repo_local_settings ).
    DATA temp3 TYPE xsdboolean.
    temp3 = boolc( iv_act = zif_abapgit_definitions=>c_action-repo_remote_settings ).
    DATA temp4 TYPE xsdboolean.
    temp4 = boolc( iv_act = zif_abapgit_definitions=>c_action-repo_background ).
    DATA temp5 TYPE xsdboolean.
    temp5 = boolc( iv_act = zif_abapgit_definitions=>c_action-repo_infos ).
    ro_menu->add(
      iv_txt = 'Repository'
      iv_act = |{ zif_abapgit_definitions=>c_action-repo_settings }?key={ iv_key }|
      iv_cur = temp1
    )->add(
      iv_txt = 'Local'
      iv_act = |{ zif_abapgit_definitions=>c_action-repo_local_settings }?key={ iv_key }|
      iv_cur = temp2
    )->add(
      iv_txt = 'Remote'
      iv_act = |{ zif_abapgit_definitions=>c_action-repo_remote_settings }?key={ iv_key }|
      iv_cur = temp3
    )->add(
      iv_txt = 'Background'
      iv_act = |{ zif_abapgit_definitions=>c_action-repo_background }?key={ iv_key }|
      iv_cur = temp4
    )->add(
      iv_txt = 'Stats'
      iv_act = |{ zif_abapgit_definitions=>c_action-repo_infos }?key={ iv_key }|
      iv_cur = temp5 ).

    zcl_abapgit_exit=>get_instance( )->enhance_repo_toolbar(
      io_menu = ro_menu
      iv_key  = iv_key
      iv_act  = iv_act ).

  ENDMETHOD.


  METHOD settings.

    ro_menu = zcl_abapgit_html_toolbar=>create( 'toolbar-abapgit-settings' ).

    DATA temp2 TYPE xsdboolean.
    temp2 = boolc( iv_act = zif_abapgit_definitions=>c_action-go_settings ).
    DATA temp3 TYPE xsdboolean.
    temp3 = boolc( iv_act = zif_abapgit_definitions=>c_action-go_settings_personal ).
    ro_menu->add(
      iv_txt = 'Global'
      iv_act = zif_abapgit_definitions=>c_action-go_settings
      iv_cur = temp2
    )->add(
      iv_txt = 'Personal'
      iv_act = zif_abapgit_definitions=>c_action-go_settings_personal
      iv_cur = temp3 ).

  ENDMETHOD.
ENDCLASS.
