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
- Joestars, Top to Bottom
![Samples/Joestars](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Joestars.png)
- Joestars, Left to Right
![Samples/Joestars_LR](https://github.com/TakeAsh/PdgToDot/raw/master/Samples/Joestars_LR.png)

## Pedigree format

### Start
```
@startPdg "<name>"
```
- The pedigree format must start `@startPdg`.
- `@startPdg` takes the diagram name option. The double quotations are required.

### Diagram attribute
```
childrenjoint <+|->
direction <TB|LR>
dpi <number>
fontname "<name>"
```
- `childrenjoint` specifies how to connect the parents and the children by default.  
When the child is only one, `+` specifies connecting the parents and the child with a joint. `-` specifies connecting the parents and the child directly.  
When the children are 2 or more, `+` specifies connecting the parents and the children with 3 joints. `-` specifies connecting the parents and the children with 1 joint.
- `direction` specifies the diagram direction. `direction` takes the option `TB` (Top to Bottom) or `LR` (Left to Right).
- `dpi` specifies the output resolution.
- `fontname` specifies the font face of the person. The double quotations are required.

### Named Attribute
```
attribute %<name> { <attribute> [, <attribute>...] }
```
- `attribute` block defines the named attribute.
- `name` must start `%` sign.
- `name` is the label, and is used for `person` later.

### Person
```
person <name> {
  <display name>
  [<comment>...]
} [<attribute> [, <attribute>...] ]
```
- `person` block difines the person.
- `name` is the label, and is used for `generation`/`family` later.
- `display name` is displayed in the diagram.
- `comment` is also displayed if exist.
- `attribute` is the named attribute or dot's attribute.
- If defining same attribute repeatedly, the latter is effective.

### Generation
```
generation { <person> <person> [<person>...] }
```
- `generation` specifies the persons that should be aligned on the same level.

### Family
```
( <person> [<person>] ) - ( [{<modify>}] <person> [{<modify>}] [<person>...] )
```
- The first block in the parenthesis indicates the parents.
- The second block in the parenthesis indicates the children.
- `modify` specifies the modification of the dot output.
    - `joint` at the top of children specifies the connection the parents and the children.
    - `joint` after a child specifies the joint connected to the child. The value is 0, 1, or 2.

### End
```
@endPdg
```
- `@endPdg` indicate the end of the pedigree format.

## Known Issue
- When the children are 3 or more, the joint - child connection might be not proper.  
Workaround: specify the joint to be connected by `joint`.  
see: [support modify for dot output](https://github.com/TakeAsh/PdgToDot/commit/35bc23d1d263707b5fd708303bacccb007a2734f)  
see: [fix Simpsons (changing joint - Patty connection manually)](https://github.com/TakeAsh/PdgToDot/commit/36274108776088cdb87cee1996bb674c4de24f2f)
