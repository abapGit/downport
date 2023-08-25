CLASS zcl_abapgit_sap_namespace DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_abapgit_sap_namespace.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAPGIT_SAP_NAMESPACE IMPLEMENTATION.


  METHOD zif_abapgit_sap_namespace~exists.
    DATA lv_editflag TYPE trnspace-editflag.
    SELECT SINGLE editflag FROM trnspace INTO lv_editflag WHERE namespace = iv_namespace.
    DATA temp1 TYPE xsdboolean.
    temp1 = boolc( sy-subrc = 0 ).
    rv_yes = temp1.
  ENDMETHOD.


  METHOD zif_abapgit_sap_namespace~is_editable.
    DATA lv_editflag TYPE trnspace-editflag.
    SELECT SINGLE editflag FROM trnspace INTO lv_editflag WHERE namespace = iv_namespace.
    DATA temp2 TYPE xsdboolean.
    temp2 = boolc( sy-subrc = 0 AND lv_editflag = 'X' ).
    rv_yes = temp2.
  ENDMETHOD.
ENDCLASS.
