CLASS zcl_abapgit_oo_factory DEFINITION PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS:
      make
        IMPORTING
          iv_object_type                   TYPE tadir-object
        RETURNING
          VALUE(ri_object_oriented_object) TYPE REF TO zif_abapgit_oo_object_fnc,

      make_by_name
        IMPORTING
          iv_object_name                   TYPE seoclsname
        RETURNING
          VALUE(ri_object_oriented_object) TYPE REF TO zif_abapgit_oo_object_fnc
        RAISING
          zcx_abapgit_exception.

  PRIVATE SECTION.
    CLASS-DATA gi_object_oriented_object TYPE REF TO zif_abapgit_oo_object_fnc .

ENDCLASS.



CLASS zcl_abapgit_oo_factory IMPLEMENTATION.


  METHOD make.
    IF gi_object_oriented_object IS BOUND.
      ri_object_oriented_object = gi_object_oriented_object.
      RETURN.
    ENDIF.
    IF iv_object_type = 'CLAS'.
      ri_object_oriented_object = NEW zcl_abapgit_oo_class( ).
    ELSEIF iv_object_type = 'INTF'.
      ri_object_oriented_object = NEW zcl_abapgit_oo_interface( ).
    ENDIF.
  ENDMETHOD.


  METHOD make_by_name.

    DATA:
      li_interface   TYPE REF TO zif_abapgit_oo_object_fnc,
      li_class       TYPE REF TO zif_abapgit_oo_object_fnc,
      ls_object_name TYPE seoclskey.

    ls_object_name-clsname = to_upper( iv_object_name ).

    li_class = NEW zcl_abapgit_oo_class( ).
    IF li_class->exists( ls_object_name ) = abap_true.
      ri_object_oriented_object = li_class.
      RETURN.
    ENDIF.

    li_interface = NEW zcl_abapgit_oo_interface( ).
    IF li_interface->exists( ls_object_name ) = abap_true.
      ri_object_oriented_object = li_interface.
      RETURN.
    ENDIF.

    zcx_abapgit_exception=>raise( |{ iv_object_name } is neither a class nor an interface| ).

  ENDMETHOD.
ENDCLASS.
