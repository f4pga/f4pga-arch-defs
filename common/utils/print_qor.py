""" Gathers statistics from VPR runs, like pack/place/route runtimes and Fmax.
"""
import argparse
import csv
import os
import sys
import subprocess


def scan_runtime(step, fname):
    """ Find runtime of VPR log (if any), else returns empty str. """
    try:
        with open(fname, 'r') as f:
            step_runtime = 0
            total_runtime = 0
            for line in f:
                if line.startswith("# {} took".format(step)):
                    step_runtime = float(line.split()[3])

                if line.startswith('The entire flow of VPR took'):
                    total_runtime = float(line.split()[6])

            step_overhead = total_runtime - step_runtime

            return str(step_runtime), str(step_overhead)
    except FileNotFoundError:
        return ""


def scan_critical(fname):
    """ Find critical path and Fmax from VPR log (if any).

    Returns
    -------
    critical_path : str
        Critical path delay in nsec
    fmax : str
        Fmax in MHz.

    """
    try:
        with open(fname, 'r') as f:
            final_cpd = 0.0
            final_fmax = 0.0

            final_cpd_geomean = 0.0
            final_fmax_geomean = 0.0

            for line in f:
                if line.startswith('Final critical path delay'):
                    parts = line.split()
                    if len(parts) >= 9:
                        # Final critical path delay (least slack): 16.8182 ns, Fmax: 59.4592 MHz
                        final_cpd = float(parts[6])
                        final_fmax = float(parts[9])
                    elif len(parts) == 8 and parts[7].strip() == 'ns':
                        # Final critical path delay (least slack): 17.9735 ns
                        final_cpd = float(parts[6])
                        final_fmax = 1000. / final_cpd

                if line.startswith(
                        'Final geomean non-virtual intra-domain period'):
                    parts = line.split()

                    final_cpd_geomean = parts[5]

                    if final_cpd_geomean == "nan":
                        final_cpd_geomean = "N/A"
                        final_fmax_geomean = "N/A"
                        continue

                    final_cpd_geomean = float(parts[5])
                    final_fmax_geomean = 1000. / final_cpd_geomean

            return str(final_cpd), str(final_fmax), str(
                final_cpd_geomean
            ), str(final_fmax_geomean)
    except FileNotFoundError:
        pass

    return "", ""


def get_last_n_dirs(path, n):
    dirs = path.split("/")
    return "/".join(dirs[-n:])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_dir")

    args = parser.parse_args()

    fields = [
        "path",
        "pack time (sec)",
        "pack overhead (sec)",
        "place time (sec)",
        "place overhead (sec)",
        "route time (sec)",
        "route overhead (sec)",
        "t_crit (ns)",
        "Fmax (MHz)",
        "t_crit geomean (ns)",
        "Fmax geomean (MHz)",
    ]

    print(
        ''.join(
            subprocess.
            getoutput('git show --oneline -s --decorate --color=never')
        ),
        file=sys.stdout
    )
    w = csv.DictWriter(sys.stdout, fields)
    w.writeheader()
    rows = list()
    for root, dirs, files in os.walk(args.build_dir):
        if 'pack.log' in files:
            d = {}

            # Get step runtimes with the respective overhead
            pack_time, pack_overhead = scan_runtime(
                "Packing", os.path.join(root, 'pack.log')
            )

            place_time, place_overhead = scan_runtime(
                "Placement", os.path.join(root, 'place.log')
            )

            route_time, route_overhead = scan_runtime(
                "Routing", os.path.join(root, 'route.log')
            )

            final_cpd, final_fmax, final_cpd_geomean, final_fmax_geomean = scan_critical(
                os.path.join(root, 'route.log')
            )

            d['path'] = get_last_n_dirs(root, 2)
            d['pack time (sec)'] = pack_time
            d['pack overhead (sec)'] = pack_overhead
            d['place time (sec)'] = place_time
            d['place overhead (sec)'] = place_overhead
            d['route time (sec)'] = route_time
            d['route overhead (sec)'] = route_overhead
            d['t_crit (ns)'] = final_cpd
            d['Fmax (MHz)'] = final_fmax
            d['t_crit geomean (ns)'] = final_cpd_geomean
            d['Fmax geomean (MHz)'] = final_fmax_geomean

            rows.append(d)

    rows = sorted(rows, key=lambda row: row['path'])

    for row in rows:
        w.writerow(row)


if __name__ == "__main__":
    main()
