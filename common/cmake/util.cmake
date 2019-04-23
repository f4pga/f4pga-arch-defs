function(get_target_property_required var target property)
  # get_target_property_required behaves like get_target_property, except
  # generates a FATAL_ERROR if the property is not found or it is empty.
  get_target_property(PROP ${target} ${property})
  if("${PROP}" STREQUAL "PROP-NOTFOUND")
    message(
      FATAL_ERROR
        "${property} not set for target ${target}, check target definition."
    )
  endif()
  if("${PROP}" STREQUAL "")
    message(
      FATAL_ERROR
        "${property} is empty for target ${target}, check target definition."
    )
  endif()
  set(${var} ${PROP} PARENT_SCOPE)
endfunction()
