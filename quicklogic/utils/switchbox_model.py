from collections import defaultdict

from data_structs import *
from utils import yield_muxes
from rr_utils import add_node, connect

# =============================================================================

class SwitchboxModel(object):
    """
    Represents a model of connectivity of a concrete instance of a switchbox.
    """

    def __init__(self, graph, loc, phy_loc, switchbox):
        self.graph = graph
        self.loc = loc
        self.phy_loc = phy_loc
        self.switchbox = switchbox

        self.mux_input_to_node = {}
        self.mux_output_to_node = {}

        self.input_to_node = {}

        self._build()

    @staticmethod
    def get_chan_dirs_for_stage(stage):
        """
        Returns channel directions for inputs and outputs of a stage.
        """

        if stage.type == "HIGHWAY":
            return "Y", "X"

        elif stage.type == "STREET":
            dir_inp = "Y" if (stage.id % 2) else "X"
            dir_out = "X" if (stage.id % 2) else "Y"
            return dir_inp, dir_out

        else:
            assert False, stage.type

    def _create_muxes(self):
        """
        Creates nodes for muxes and internal edges within them. Annotates the
        internal edges with fasm data.

        Builds maps of muxs' inputs and outpus to VPR nodes.
        """

        # Build mux driver timing map. Assign each mux output its timing data
        driver_timing = {}
        for connection in self.switchbox.connections:
            src = connection.src
            dst = connection.dst

            stage = self.switchbox.stages[src.stage_id]
            switch = stage.switches[src.switch_id]
            mux = switch.muxes[src.mux_id]
            pin = mux.inputs[src.pin_id]

            if pin.id not in mux.timing:
                continue

            timing = mux.timing[pin.id].driver

            key = (src.stage_id, src.switch_id, src.mux_id)
            if key in driver_timing:
                assert driver_timing[key] == timing, \
                    (self.loc, key, driver_timing[key], timing)
            else:
                driver_timing[key] = timing

        # Create muxes
        segment_id = self.graph.get_segment_id_from_name("sbox")

        for stage, switch, mux in yield_muxes(self.switchbox):
            dir_inp, dir_out = self.get_chan_dirs_for_stage(stage)

            # Output node
            key = (stage.id, switch.id, mux.id)
            assert key not in self.mux_output_to_node

            out_node = add_node(self.graph, self.loc, dir_out, segment_id)
            self.mux_output_to_node[key] = out_node

            # Intermediate output node
            int_node = add_node(self.graph, self.loc, dir_out, segment_id)

            # Get switch id for the switch assigned to the driver. If
            # there is none then use the delayless switch. Probably the
            # driver is connected to a const.
            if key in driver_timing:
                switch_id = self.graph.get_switch_id(
                    driver_timing[key].vpr_switch
                )
            else:
                switch_id = self.graph.get_delayless_switch_id()

            # Output driver edge
            connect(
                self.graph,
                int_node,
                out_node,
                switch_id=switch_id,
                segment_id=segment_id,
            )

            # Input nodes + mux edges
            for pin in mux.inputs.values():

                key = (stage.id, switch.id, mux.id, pin.id)
                assert key not in self.mux_input_to_node

                # Input node
                inp_node = add_node(self.graph, self.loc, dir_inp, segment_id)
                self.mux_input_to_node[key] = inp_node

                # Get mux metadata
                metadata = self.get_metadata_for_mux(
                    self.phy_loc, stage, switch, mux, pin.id
                )

                if len(metadata):
                    meta_name = "fasm_features"
                    meta_value = "\n".join(metadata)
                else:
                    meta_name = None
                    meta_value = ""

                # Get switch id for the switch assigned to the mux edge. If
                # there is none then use the delayless switch. Probably the
                # edge is connected to a const.
                if pin.id in mux.timing:
                    switch_id = self.graph.get_switch_id(
                        mux.timing[pin.id].sink.vpr_switch
                    )
                else:
                    switch_id = self.graph.get_delayless_switch_id()

                # Mux switch with appropriate timing and fasm metadata
                connect(
                    self.graph,
                    inp_node,
                    int_node,
                    switch_id=switch_id,
                    segment_id=segment_id,
                    meta_name=meta_name,
                    meta_value=meta_value,
                )

    def _connect_muxes(self):
        """
        Creates VPR edges that connects muxes within the switchbox.
        """

        segment_id = self.graph.get_segment_id_from_name("sbox")
        switch_id = self.graph.get_switch_id("short")

        # Add internal connections between muxes.
        for connection in self.switchbox.connections:
            src = connection.src
            dst = connection.dst

            # Check
            assert src.pin_id == 0, src
            assert src.pin_direction == PinDirection.OUTPUT, src

            # Get the input node
            key = (dst.stage_id, dst.switch_id, dst.mux_id, dst.pin_id)
            dst_node = self.mux_input_to_node[key]

            # Get the output node
            key = (src.stage_id, src.switch_id, src.mux_id)
            src_node = self.mux_output_to_node[key]

            # Connect
            connect(
                self.graph,
                src_node,
                dst_node,
                switch_id=switch_id,
                segment_id=segment_id
            )

    def _create_input_drivers(self):
        """
        Creates VPR nodes and edges that model input connectivity of the
        switchbox.
        """

        # Create a driver map containing all mux pin locations that are
        # connected to a driver. The map is indexed by (pin_name, vpr_switch)
        # and groups togeather inputs that should be driver by a specific
        # switch due to the timing model.
        driver_map = defaultdict(lambda: [])

        for pin in self.switchbox.inputs.values():
            for loc in pin.locs:

                stage = self.switchbox.stages[loc.stage_id]
                switch = stage.switches[loc.switch_id]
                mux = switch.muxes[loc.mux_id]
                pin = mux.inputs[loc.pin_id]

                if pin.id not in mux.timing:
                    vpr_switch = None
                else:
                    vpr_switch = mux.timing[pin.id].driver.vpr_switch

                key = (pin.name, vpr_switch)
                driver_map[key].append(loc)

        # Create input nodes for each input pin
        segment_id = self.graph.get_segment_id_from_name("sbox")

        for pin in self.switchbox.inputs.values():

            node = add_node(self.graph, self.loc, "Y", segment_id)

            assert pin.name not in self.input_to_node, pin.name
            self.input_to_node[pin.name] = node

        # Create driver nodes, connect everything
        for (pin_name, vpr_switch), locs in driver_map.items():

            # Create the driver node
            drv_node = add_node(self.graph, self.loc, "X", segment_id)

            # Connect input node to the driver node. Use the switch with timing.
            inp_node = self.input_to_node[pin_name]

            # Get switch id for the switch assigned to the driver. If
            # there is none then use the delayless switch. Probably the
            # driver is connected to a const.
            if vpr_switch is not None:
                switch_id = self.graph.get_switch_id(vpr_switch)
            else:
                switch_id = self.graph.get_delayless_switch_id()

            # Connect
            connect(
                self.graph,
                inp_node,
                drv_node,
                switch_id=switch_id,
                segment_id=segment_id
            )

            # Now connect the driver node with its loads
            switch_id = self.graph.get_switch_id("short")
            for loc in locs:

                key = (loc.stage_id, loc.switch_id, loc.mux_id, loc.pin_id)
                dst_node = self.mux_input_to_node[key]

                connect(
                    self.graph,
                    drv_node,
                    dst_node,
                    switch_id=switch_id,
                    segment_id=segment_id
                )

    def _build(self):
        """
        Build the switchbox model
        """

        # Create and connect muxes
        self._create_muxes()
        self._connect_muxes()

        # Create and connect input drivers models
        self._create_input_drivers()

    @staticmethod
    def get_metadata_for_mux(loc, stage, switch, mux, pin_id):
        """
        Formats fasm features for the given edge representin a switchbox mux.
        Returns a list of fasm features.
        """
        metadata = []

        # Format prefix
        prefix = "X{}Y{}.ROUTING".format(loc.x, loc.y)

        # A mux in the HIGHWAY stage
        if stage.type == "HIGHWAY":
            feature = "I_highway.IM{}.I_pg{}".format(switch.id, pin_id)

        # A mux in the STREET stage
        elif stage.type == "STREET":
            feature = "I_street.Isb{}{}.I_M{}.I_pg{}".format(
                stage.id + 1, switch.id + 1, mux.id, pin_id
            )

        else:
            assert False, stage

        metadata.append(".".join([prefix, feature]))
        return metadata

    def get_input_node(self, pin_name):
        """
        Returns a VPR node associated with the given input of the switchbox
        """
        return self.input_to_node[pin_name]

    def get_output_node(self, pin_name):
        """
        Returns a VPR node associated with the given output of the switchbox
        """

        # Get the output pin
        pin = self.switchbox.outputs[pin_name]

        assert len(pin.locs) == 1
        loc = pin.locs[0]

        # Return its node
        key = (loc.stage_id, loc.switch_id, loc.mux_id)
        return self.mux_output_to_node[key]


