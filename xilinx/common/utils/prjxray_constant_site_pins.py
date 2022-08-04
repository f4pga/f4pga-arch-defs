""" This file defines tieable wires in 7-series designs.

FEATURES_WHEN_ROUTED is a map of wires connected to site pins to a FASM feature.
If the wire is routed from the general routing network, then this feature must
also be emitted.

WIRE_TIE_OPTIONS is a map of wires connected to site pins to the list of tie
options available for the pin.

"""

# Using these wires requires a mux to be enabled.
FEATURES_WHEN_ROUTED = {
    # 'CLBLL_L_SR': 'SLICEL_X1.SRUSEDMUX',
    # 'CLBLM_L_SR': 'SLICEL_X1.SRUSEDMUX',
    # 'CLBLL_LL_SR': 'SLICEL_X0.SRUSEDMUX',
    # 'CLBLM_M_SR': 'SLICEM_X0.SRUSEDMUX',
    # 'CLBLL_L_CE': 'SLICEL_X1.CEUSEDMUX',
    # 'CLBLM_L_CE': 'SLICEL_X1.CEUSEDMUX',
    # 'CLBLL_LL_CE': 'SLICEL_X0.CEUSEDMUX',
    # 'CLBLM_M_CE': 'SLICEM_X0.CEUSEDMUX',
}

# What tie options are available for this site pin.
WIRE_TIE_OPTIONS = {
    # 'CLBLL_L_SR': [0],
    # 'CLBLM_L_SR': [0],
    # 'CLBLL_LL_SR': [0],
    # 'CLBLM_M_SR': [0],
    # 'CLBLL_L_CE': [1],
    # 'CLBLM_L_CE': [1],
    # 'CLBLL_LL_CE': [1],
    # 'CLBLM_M_CE': [1],
}


def yield_ties_to_wire(wire):
    """ Given the name of the wire, yields available constant tie options.

    Args:
        wire(str): The name of the tile wire connected to a site pin.
            If the wire name is not found, yields nothing.

    It is not an error to call this function with wires that are not connected
    to site pins, as the function will yield nothing.

    """
    if wire not in WIRE_TIE_OPTIONS:
        return

    for constant in WIRE_TIE_OPTIONS[wire]:
        yield constant


def feature_when_routed(wire):
    """ Given the name of the wire, returns None or a required feature.

    Args:
        wire(str): The name of the tile wire connected to a site pin.
            If the wire name is not found, returns None.

    It is not an error to call this function with wires that are not connected
    to site pins, as the function will return None.

    """
    if wire in FEATURES_WHEN_ROUTED:
        return FEATURES_WHEN_ROUTED[wire]
