
from .core cimport graph_vertex, graph_arc, EdgeManager
from .graph cimport Graph

cdef struct hamcycle_vertex:
	graph_vertex vertex
	(graph_arc *) endpoint, removed_arcs, cycle_edge
	graph_vertex *last_anchor

cdef class HamCycleGraph(Graph):

	cdef size_t vertex_size(self):
		return sizeof(hamcycle_vertex)


	cdef size_t find_hamcycles(self):

		# first find out if graph is connected

		if not self.connected():
			return 0
