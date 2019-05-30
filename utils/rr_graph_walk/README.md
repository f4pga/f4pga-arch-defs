# Routing graph traversal (walk) utility

This utility script allows to walk through the routing graph from a given
starting node id to a given target node id. If the target node id is not
given then it lists all available routes which start at the starting node.

Output route(s) are written to a file as separate lines. Each line contain
comma separated IDs of all visited nodes for a route.

! IMPORTANT ! This tool is implemented suboptimally and consumes a HUGE amounts
of memory (typically 11GB for the prjxray rr graph).
