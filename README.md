galxe -- graph algorithm extensions for python
==============================================

Various graph algorithms from graph theory made available
via c extensions in python.

Extension modules are written in Cython and c.

Stable versions without the Cython sources exist as a
[pypi project](https://pypi.python.org/pypi/galxe/)  as well.

Initial Motivation
------------------

Past experience with direct translation to python shared libraries using boost
left much to be desired in flexibility, compile time and binary size.

After finally trying to write a cpython extension from scratch
and experiencing how tedious it can be, Cython was discovered.

Being able to easily see the generated code with Cython was a huge plus,
especially after trying to use the Python headers directly.

### Hamilton Cycles ###

This project started as a re-imagining of thesis work found at
[hamilton_cycle](https://github.com/aachalat/hamilton_cycle).

The initial goals were as follows:

* remove all direct use of |V| length arrays used
  in the hamcycle algorithm or its various dfs support algorithms.

* write the code and comments in terms of graph minors, hopefully making the algorithm more understandable


Other than a degree list, the algorithms did not need to rely on random
access to vertex data. The performance penalty of O(logN) for random vertex
lookup did not seem to be a very big deal.

The approach since then has been to eliminate degree lists entirely in the
hamcycle algorithm (since we only really care about vertices of degree one
or two).

The performance hit of checking an adjacency list up to the third entry
seems to be offset by the fact that a degree list is no longer maintained.


### Evolving Motivation ###

The initial motivation has now morphed into a more general purpose
graph algorithm project (still mostly centered around the hamcycle code).

The ability to switch back and forth from python and c, use of
python exceptions, access to python's string and file io libraries (actually all of the python libraries) and no longer caring about memory management as much make actually focusing on algorithm development a lot more fun.

In the [short term](#overall-goals-and-algorithm-status) focus is still
on the hamcycle algorithm, but will be moving more towards
getting di-graphs to work as well as some network flow algorithms.

Numpy integration (matrices) so that algebraic graph theory algorithms can be switch back and forth from is also something of a medium to longer term project.

Examples
--------

Create a simple undirected graph and populate it with some vertices and
edges:

```python

from galxe.graph import Graph

g = Graph()
g += 1 # ensure vertex with label "1" exists

g += (10, 11) # ensure vertices with labels "10" and "11" exist and ensure
              # they are connected with an edge

g += [1, 2, 3, 4] # ensure vertex 1 .. 4 exist and ensure edges
                  # (1,2), (1,3) and (1,4) exist

g[1]  # get a list of all vertices (actually the integer labels) adjacent to "1"
> [4, 3, 2]

g2 = Graph(g)  # create a copy of g
print(g2)
> Graph([[1, 2, 3, 4], [10, 11]])

g.make_repr(sort=True) # create a list based representation of graph instance "g"
> [[1, 2, 3, 4], [10, 11]]

# list based representations can be used to construct a new graph:
print Graph(g.make_repr())
>Graph([[1, 2, 3, 4], [10, 11]])

```

Try some algorithms out:

```python

from galxe.graph import Graph
from galxe.hamcycle import hc_count

# create a random graph on 10 vertices and up to 15 edges
g = Graph.random_graph(10, 15)
print(g)
> Graph([[1, 6],
> [2, 5, 7],
> [3, 6, 8, 9],
> [4, 8],
> [5, 7, 9, 10],
> [7, 9],
> [8, 9, 10],
> [9, 10]])

g.connected()  # is graph connected (uses modified components algorithm in dfs.pyx)
> True

hc_count(g) # any hamcycles??
> 0

```

Installation
------------

The python headers and a compatible compiler need to be
installed.  Current versions of gcc (on linux) and clang (on OSX) have
been used successfully.

[Cython](http://cython.org/) is required if you
are building from the github [repository](https://github.com/aachalat/galxe), but the PyPi [version](https://pypi.python.org/pypi/galxe) does
not require Cython at all (pyx/pxd files are actually not included).

The setup.py file just uses distutils so the standard python
installation patterns should work.

If make is available a few shortcuts to using setup.py exist.

```bash
# clean up the build and galxe folders
make clean

# create a source distribution
make sdist

# create an inplace build of the modules in the galxe/ subfolder
make # same as python setup.py build_ext --inplace

```
Otherwise just use setup.py directly. ie.

```bash
python setup.py install --help  # list install options

python setup.py install --user  # install to current user's package folder

# if you have the right permissions and like to pollute your
# main distribution folders with alpha level code

python setup.py install
```

### Testing ###

Before running the ```python setup.py install``` command a few test
to try might be:

```bash
# just build extension modules in place and test by generating and printing a
# random graph with 20 vertices and up to 20 edges, and then print a
# representative vertex of each connected component of the generated graph.
make && cat <<EOF | python
from galxe.graph import Graph
g = Graph.random_graph(20,20)
print(g)
print(g.components())
EOF

# make a complete graph on 10 vertices and
# return the number of hamilton cycles
make && cat <<EOF | python
from galxe.graph import Graph
from galxe.hamcycle import hc_count
g = Graph()
x = range(1,11,1)
while x:
    g+=x
    x.pop(0)
print(g)
print("hamcycles: %i" % hc_count(g))
EOF

# you can try larger complete graphs but running time gets exponentially longer


```

Overall Goals and Algorithm Status
----------------------------------



###hamcycle current status###

Found in [galxe/hamcycle.pyx](https://github.com/aachalat/galxe/blob/master/galxe/hamcycle.pyx)

- [x] re-implement multi-path portion of the algorithm and frame it in terms
      of graph minor reductions on a graph
- [x] implement hamiton cycle counts
- [ ] implement is_hamiltonian test (stop when cycle count hits 1)
- [ ] return actual cycles found (as a graph instance)
- [ ] check pointing of search so that it can be restarted or
      distributed to another process
- [ ] re-implement search space pruning from thesis.
- [ ] switch to an incremental dfs when ascending/pruning the search space

### undirected simple graphs ###
- [x] reading and writing [gng](http://www.combinatorialmath.ca/G&G/) style graph txt format (galxe.graph.write_file / galxe.graph.parse_file)
- [ ] allow edge and vertex deletions from a graph
- [ ] define graph subtraction methods (graph - vertex, graph - edge, graph - graph)
