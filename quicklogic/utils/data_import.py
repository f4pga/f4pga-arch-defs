"""
Functions related to parsing and processing of data stored in a QuickLogic
TechFile.
"""
import xml.etree.ElementTree as ET

from data_structs import *

# =============================================================================


def parse_switchbox(xml_sbox, xml_common = None):
    """
    Parses the switchbox definition from XML. Returns a Switchbox object
    """
    switchbox = Switchbox(type=xml_sbox.tag)

    # Identify stages. Append stages from the "COMMON_STAGES" section if
    # given.
    stages = [n for n in xml_sbox if n.tag.startswith("STAGE")]

    if xml_common is not None:
        common_stages = [n for n in xml_common if n.tag.startswith("STAGE")]
        stages.extend(common_stages)

    # Load stages
    for xml_stage in stages:

        # Get stage id
        stage_id  = int(xml_stage.attrib["StageNumber"])
        assert stage_id not in switchbox.stages, (stage_id, switchbox.stages.keys())

        stage_type = xml_stage.attrib["StageType"]

        # Add the new stage
        stage = Switchbox.Stage(
            id   = stage_id,
            type = xml_stage.attrib["StageType"]
        )
        switchbox.stages[stage_id] = stage

        # Process outputs
        switches = {}
        for xml_output in xml_stage.findall("Output"):
#            output_num  = int(xml_output.attrib["Number"])
            out_switch_id = int(xml_output.attrib["SwitchNum"])
            out_pin_id    = int(xml_output.attrib["SwitchOutputNum"])
            out_pin_name  = xml_output.get("JointOutputName", None)

            # Add a new switch if needed
            if out_switch_id not in switches:
                switches[out_switch_id] = Switchbox.Switch(out_switch_id, stage_id)
            switch = switches[out_switch_id]

            # Add the output
            switch.pins.append(Switchbox.Pin(
                id=out_pin_id,
                name=out_pin_name,
                direction=PinDirection.OUTPUT
                ))

#            # Add as top level output
#            if stage_id == (num_stages -1):
#                switchbox.pins.append(Port(
#                id=output_num,
#                name=output_name
#                ))

            # Process inputs
            for xml_input in xml_output:
                inp_pin_name = xml_input.get("WireName", None)

                inp_pin_id  = int(xml_input.tag.replace("Input", ""))
                assert inp_pin_id < 10, inp_pin_id
                inp_pin_id += out_pin_id * 10


                # Add the input
                switch.pins.append(Switchbox.Pin(
                    id=inp_pin_id,
                    name=inp_pin_name,
                    direction=PinDirection.INPUT
                    ))

#                # Add as top level input
#                if stage_id == 0:
#                    switchbox_inputs.append(Port(
#                        id=-1,
#                        name=input_name
#                        ))

                # Add internal connection
                if stage_type == "STREET" and stage_id > 0:
                    conn_stage     = int(xml_input.attrib["Stage"])
                    conn_switch_id = int(xml_input.attrib["SwitchNum"])
                    conn_pin_id    = int(xml_input.attrib["SwitchOutputNum"])

                    conn = Switchbox.Connection(
                        src_stage=conn_stage,
                        src_switch=conn_switch_id,
                        src_pin=conn_pin_id,
                        dst_stage=stage_id,
                        dst_switch=switch.id,
                        dst_pin=inp_pin_id
                    )

                    assert conn not in switchbox.connections, conn
                    switchbox.connections.add(conn)

        # Add switches to the stage
        stage.switches = list(switches.values())

    return switchbox

# =============================================================================


def import_data(xml_root):
    """
    Imports the Quicklogic FPGA tilegrid and routing data from the given
    XML tree
    """

    # Get the "Routing" section
    xml_routing = xml_root.find("Routing")
    assert xml_routing is not None

    # Import switchboxes
    switchboxes = []
    for xml_node in xml_routing:

        # Not a switchbox
        if not xml_node.tag.endswith("_SBOX"):
            continue

        # Load all "variants" of the switchbox
        xml_common = xml_node.find("COMMON_STAGES")
        for xml_sbox in xml_node:
            if xml_sbox != xml_common:
                switchboxes.append(parse_switchbox(xml_sbox, xml_common))

    return switchboxes ,

