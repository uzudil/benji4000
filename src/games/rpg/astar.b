#  astar-list.js http://github.com/bgrins/javascript-astar
#    MIT License
#    
#    ** You should not use this implementation (it is quite slower than the heap implementation) **
#    
#    Implements the astar search algorithm in javascript
#    Based off the original blog post http://www.briangrinstead.com/blog/astar-search-algorithm-in-javascript
#    It has since been replaced with astar.js which uses a Binary Heap and is quite faster, but I am leaving
#    it here since it is more strictly following pseudocode for the Astar search
#    **Requires graph.js**
#

def manhattan(pos0, pos1) {
    # See list of heuristics: http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
    d1 := abs(pos1.x - pos0.x);
    d2 := abs(pos1.y - pos0.y);
    return d1 + d2;
}

def newGridNode(x, y, blocked) {
    return {
        "x": x,
        "y": y,
        "pos": { "x": x, "y": y },
        "blocked": blocked,
        "f": 0,
        "g": 0,
        "h": 0,
        "visited": false,
        "closed": false,
        "debug": "",
        "parent": null,
    };
}

def astarInit(grid) {
    x := 0;
    while(x < len(grid)) {
        y := 0;
        while(y < len(grid[x])) {
            grid[x][y].f := 0;
            grid[x][y].g := 0;
            grid[x][y].h := 0;
            grid[x][y].visited := false;
            grid[x][y].closed := false;
            grid[x][y].debug := "";
            grid[x][y].parent := null;
            y := y + 1;
        }
        x := x + 1;
    }
}

def astarSearch(grid, start, end) {
    astarInit(grid);
    heuristic := manhattan;

    openList   := [];
    openList[len(openList)] := start;

    #trace("start=" + start);
    #trace("end=" + end);

    while(len(openList) > 0) {

        # Grab the lowest f(x) to process next
        lowInd := 0;
        i := 0;
        while(i < len(openList)) {
            if(openList[i].f < openList[lowInd].f) { lowInd := i; }
            i := i + 1;
        }
        currentNode := openList[lowInd];

        #trace("currentNode=" + currentNode);
        #trace("openList=" + openList);

        # End case -- result has been found, return the traced path
        if(currentNode.x = end.x && currentNode.y = end.y) {
            curr := currentNode;
            ret := [];
            while(curr.parent != null) {
                ret[len(ret)] := curr;
                curr := curr.parent;
            }
            return array_reverse(ret);
        }

        # Normal case -- move currentNode from open to closed, process each of its neighbors
        del openList[lowInd];
        currentNode.closed := true;

        neighbors := astarNeighbors(grid, currentNode);
        #trace("neighbors=" + neighbors);
        i := 0;
        while(i < len(neighbors)) {
            neighbor := neighbors[i];

            # process only valid nodes
            if(neighbor.closed = false && neighbor.blocked = false) {

                # g score is the shortest distance from start to current node, we need to check if
                #   the path we have arrived at this neighbor is the shortest one we have seen yet
                # adding 1: 1 is the distance from a node to it's neighbor
                gScore := currentNode.g + 1; 
                gScoreIsBest := false;

                if(neighbor.visited = false) {
                    # This the the first time we have arrived at this node, it must be the best
                    # Also, we need to take the h (heuristic) score since we haven't done so yet

                    gScoreIsBest := true;
                    neighbor.h := heuristic(neighbor.pos, end.pos);
                    neighbor.visited := true;
                    openList[len(openList)] := neighbor;
                } else {
                    if(gScore < neighbor.g) {
                        # We have already seen the node, but last time it had a worse g (distance from start)
                        gScoreIsBest := true;
                    }
                }

                if(gScoreIsBest) {
                    # Found an optimal (so far) path to this node.  Store info on how we got here and
                    #  just how good it really is...
                    neighbor.parent := currentNode;
                    neighbor.g := gScore;
                    neighbor.f := neighbor.g + neighbor.h;
                    neighbor.debug := "F: " + neighbor.f + " G: " + neighbor.g + " H: " + neighbor.h;
                }
            }

            i := i + 1;
        }
    }

    # No result was found -- empty array signifies failure to find path
    return [];
}

def astarNeighbors(grid, node) {
    ret := [];
    x := node.x;
    y := node.y;

    if(x - 1 > 0) {
        ret[len(ret)] := grid[x-1][y];
    }
    if(x + 1 < len(grid)) {
        ret[len(ret)] := grid[x+1][y];
    }
    if(y - 1 > 0) {
        ret[len(ret)] := grid[x][y-1];
    }
    if(y + 1 < len(grid[x])) {
        ret[len(ret)] := grid[x][y+1];
    }
    return ret;
}
