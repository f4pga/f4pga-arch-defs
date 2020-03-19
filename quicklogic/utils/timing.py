import itertools
import statistics

from data_structs import *
from utils import yield_muxes, add_named_item

# =============================================================================


def linear_regression(xs, ys):
    """
    Computes linear regression coefficients
    https://en.wikipedia.org/wiki/Simple_linear_regression

    Returns a and b coefficients of the function f(y) = a * x + b
    """
    x_mean = statistics.mean(xs)
    y_mean = statistics.mean(ys)

    num, den = 0.0, 0.0
    for x, y in zip(xs, ys):
        num += (x - x_mean) * (y - y_mean)
        den += (x - x_mean) * (x - x_mean) 

    a = num / den
    b = y_mean - a * x_mean

    return a, b


def process_timing_data(timing_data):
    """
    Processes the timing data. Converts delays for each mux (joint) edge
    to: a constant delay, edge switch resistance and mux load capacitance.
    """

    def yield_timings():
        """
        A helper generator
        """
        for stage_id, stage_timing in timing_data.items():
            for switch_id, switch_timing in stage_timing.items():
                for mux_id, mux_timing in switch_timing.items():
                    for pin_id, edge_timing in mux_timing.items():
                        yield stage_id, switch_id, mux_id, pin_id, edge_timing

    # An error threshold
    ERROR_THRESHOLD = 0.5  #0.025

    # Scaling factor
    fac = 1.0

    # Process edge timings
    timing_models = {}
    for stage_id, switch_id, mux_id, pin_id, edge_delays in yield_timings():
        idstr = "{}.{}.{}.{}".format(stage_id, switch_id, mux_id, pin_id)

        # Must have delay data for at least two load counts to determine common
        # propagation delay and a single load capacitance.
        assert len(edge_delays) > 1

        # Must have delays for all load counts
        max_loads = max(edge_delays.keys())
        assert list(edge_delays.keys()) == list(range(1, max_loads+1)), \
               list(edge_delays.keys())

        # Take the worst case delay
        edge_delays = {n: max(ts) for n, ts in edge_delays.items()}

        # Collect data for linear regression. Compute the regression
        xs = sorted(edge_delays.keys())
        ys = [edge_delays[x] for x in xs]

        a, b = linear_regression(xs, ys)

        # Cannot have a < 0 (decreasing relation). If such thing happens make the
        # regression line flat.
        if a < 0.0:
            print("WARNING: For '{}' the delay decreases with the increasing load count! (a={:.3f})".format(idstr, a))
            a = 0.0

        # Cannot have any delay higher than the model. Check if all delays lay
        # below the regression line and if not then shift the line up accordingly.
        for x, y in zip(xs, ys):
            t = a * x + b
            if y > t:
                b += y - t

        # Assumed switch capacitance of a single load [F]
        c = 10.0 * 1e-12  # 10pF

        # Compute switch Tdel and R in nanoseconds
        r = 1e-9 * a / (fac * c)
        tdel = b

        # Compute error, check if if the model makes sense
        err = {n: abs(d - (tdel + n * fac * r * c * 1e9)) for n, d in edge_delays.items()}
        err_max = max(err.values())

        if err_max > ERROR_THRESHOLD:

            print("WARNING: Error of the timing model of '{}' is too high:".format(idstr))
            print("---------------------------------------------")
            print("| # loads  | actual   | model    | error    |")
            print("|----------+----------+----------+----------|")
            
            for n, e in err.items():
                d = edge_delays[n]
                m = tdel + n * fac * r * c * 1e9
                e = d - m
                print("| {:<9}| {:<9.3f}| {:<9.3f}| {:<9.3f}|".format(n, d, m, e))

            print("---------------------------------------------")
            print("")

        # Convert tdel to seconds
        tdel *= 1e-9

        # Store the timing model
        timing_models[(stage_id, switch_id, mux_id, pin_id)] = \
            EdgeTimingModel(tdel = tdel, r = r, c = c)

    return timing_models

# =============================================================================


def create_vpr_switch(type, tdel, r, c):
    """
    Creates a VPR switch with the given parameters. Autmatically generates
    its name with these parameters encoded.

    The VPR switch parameters are:
    - type: Switch type. See VPR docs for the available types
    - tdel: Constant propagation delay [s]
    - r:    Internal resistance [ohm]
    - c:    Internal capacitance (active only when the switch is "on") [F]
    """

    # Format the switch name
    name  = ["sw"]
    name += ["T{:>08.6f}".format(tdel * 1e9)]
    name += ["R{:>08.6f}".format(r)]
    name += ["C{:>09.6f}".format(c * 1e12)]

    # Create the VPR switch
    switch = VprSwitch(
        name  = "_".join(name),
        type  = type,
        t_del = tdel,
        r     = r,
        c_in  = 0.0,
        c_out = 0.0,
        c_int = c,
    )

    return switch


def populate_switchbox_timing(switchbox, timing_models, vpr_switches, vpr_segments):
    """
    Populates the timing model to the switchbox
    """

    for key, timing_model in timing_models.items():
        stage_id, switch_id, mux_id, pin_id = key

        # Get the mux, create timing data entry
        mux = switchbox.stages[stage_id].switches[switch_id].muxes[mux_id]

        if mux.timing is None:
            mux.timing = Switchbox.Mux.Timing()

        # Store the timing model
        assert pin_id not in mux.timing.edge_timing
        mux.timing.edge_timing[pin_id] = timing_model

        # Create a VPR switch or get an existing one for the edge
        vpr_switch = create_vpr_switch("mux", timing_model.tdel, timing_model.r, 0.0)
        vpr_switch = add_named_item(vpr_switches, vpr_switch, vpr_switch.name)

        assert pin_id not in mux.timing.edge_switch
        mux.timing.edge_switch[pin_id] = vpr_switch.name

        # Store the load capacitance.
        # Note: since each mux edge goes to the same output, the load
        # capacitance in each edge timing model must be the same. Hence it's
        # value is fixed during the timing model generation.
        if mux.timing.load_c is None:
            mux.timing.load_c = timing_model.c

        else:
            assert abs(mux.timing.load_c - timing_model.c) < 1e-15, \
                (mux.timing.load_c, timing_model.c)

        # Create a load switch with the specific internal capacitance and
        # assign it to the mux
        if mux.timing.load_switch is None:
            vpr_switch = create_vpr_switch("mux", 0.0, 0.0, mux.timing.load_c)
            vpr_switch = add_named_item(vpr_switches, vpr_switch, vpr_switch.name)

            mux.timing.load_switch = vpr_switch.name       
