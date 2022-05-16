""" Generate timing summary from Vivado timing.json output. """
import argparse
import json


def timing_summary(timing_json):
    setups = []
    holds = []
    for net in timing_json:
        for ipin in net['ipins']:
            if 'setup_timing_path' in ipin and ipin['setup_timing_path'
                                                    ]['SLACK'] != "":
                setups.append(ipin)
            if 'hold_timing_path' in ipin and ipin['hold_timing_path']['SLACK'
                                                                       ] != "":
                holds.append(ipin)

    worst_setup_slack = min(
        setups, key=lambda setup: float(setup['setup_timing_path']['SLACK'])
    )

    worst_hold_slack = min(
        holds, key=lambda hold: float(hold['hold_timing_path']['SLACK'])
    )

    print(
        'Worst setup slack: {} = {}'.format(
            worst_setup_slack['setup_timing_path']['NAME'],
            worst_setup_slack['setup_timing_path']['SLACK']
        )
    )
    print(
        'Worst hold slack: {} = {}'.format(
            worst_hold_slack['hold_timing_path']['NAME'],
            worst_hold_slack['hold_timing_path']['SLACK']
        )
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('timing_json')

    args = parser.parse_args()

    with open(args.timing_json) as f:
        timing_json = json.load(f)

    timing_summary(timing_json)


if __name__ == "__main__":
    main()
