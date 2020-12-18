CLASS zcl_abapgit_object_ecsd DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_object_ecatt_super
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS:
      constructor
        IMPORTING
          !is_item     TYPE zif_abapgit_definitions=>ty_item
          !iv_language TYPE spras.

  PROTECTED SECTION.
    METHODS:
      get_object_type REDEFINITION,
      get_upload REDEFINITION,
      get_download REDEFINITION,
      get_lock_object REDEFINITION.

ENDCLASS.



CLASS zcl_abapgit_object_ecsd IMPLEMENTATION.


  METHOD constructor.

    super->constructor( is_item     = is_item
                        iv_language = iv_language ).

  ENDMETHOD.


  METHOD get_object_type.

    rv_object_type = cl_apl_ecatt_const=>obj_type_system_data.

  ENDMETHOD.

  METHOD get_upload.

    ro_upload = NEW zcl_abapgit_ecatt_system_upl( ).

  ENDMETHOD.

  METHOD get_download.

    ro_download = NEW zcl_abapgit_ecatt_system_downl( ).

  ENDMETHOD.

  METHOD get_lock_object.

    rv_lock_object = 'E_ECATT_SD'.

  ENDMETHOD.

ENDCLASS.
