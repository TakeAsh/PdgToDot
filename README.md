# PdgToDot
- draw a pedigree diagram with Graphviz dot.
- [Graphviz - Graph Visualization Software](http://www.graphviz.org/)
- [Family tree layout with Dot/GraphViz - Stack Overflow](https://stackoverflow.com/questions/2271704/)
- [dot - In Graphviz, how do I align an edge to the top center of a node? - Stack Overflow](https://stackoverflow.com/questions/27504703/)

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

## Samples
- Isonos, Top to Bottom
![Samples/Isono](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Isono.png)
- Isonos, Left to Right
![Samples/Isono_LR](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Isono_LR.png)
- Simpsons, Top to Bottom
![Samples/Simpsons](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Simpsons.png)
- Simpsons, Left to Right
![Samples/Simpsons_LR](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Simpsons_LR.png)

## Known Issue
- When the children are 3 or more, the joint - child connection might be not proper.  
Workaround: change the connection in the dot file manually.  
see: [fix Simpsons (changing joint - Patty connection manually)](https://github.com/TakeAsh/PdgToDot/commit/36274108776088cdb87cee1996bb674c4de24f2f)
