# PdgToDot
- convert Pedigree to Graphviz dot.
- [Graphviz - Graph Visualization Software](http://www.graphviz.org/)
- [Family tree layout with Dot/GraphViz - Stack Overflow](https://stackoverflow.com/questions/2271704/)

## Usage
Make .pdg file, convert it to .dot, and convert it to .svg/.png.
```
./PdgToDot.pl Samples/Isono.pdg
dot -Tsvg -o Samples/Isono.svg Samples/Isono.dot
```
Or,
```
cat Samples/Isono.pdg | ./PdgToDot.pl - | dot -Tsvg -o Samples/Isono.svg
```
![Samples/Isono](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Isono.png)
