# todo: move to go
# is point (x,y) inside rect (rx,ry,rx2,ry2) ?
def isInclude(x, y, rx, ry, rx2, ry2) {
    return x >= rx && x <= rx2 && y >= ry && y <= ry2;
}

# todo: move to go
# do rects (ax1, ay1, ax2, ay2) overlap with rect (bx1, by1, bx2, by2) ?
def isOverlap(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2) {
    return isInclude(ax1, ay1, bx1, by1, bx2, by2) || 
        isInclude(ax2, ay1, bx1, by1, bx2, by2) ||
        isInclude(ax1, ay2, bx1, by1, bx2, by2) ||
        isInclude(ax2, ay2, bx1, by1, bx2, by2) ||
        isInclude(bx1, by1, ax1, ay1, ax2, ay2) ||
        isInclude(bx1, by2, ax1, ay1, ax2, ay2) ||
        isInclude(bx2, by1, ax1, ay1, ax2, ay2) ||
        isInclude(bx2, by2, ax1, ay1, ax2, ay2);
}
