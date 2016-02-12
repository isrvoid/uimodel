module uimodel.navigation.tree_parser;

import std.algorithm;
import std.traits;
import std.range;
import std.uni : isWhite;
import std.array : array, Appender;

import uimodel.uiobject;
import uimodel.navigation.tree;

@safe:

private enum Msg : string
{
    rootIsIndented = "Tree root must be at the beginning of the line.",
    wrongIndentation = "Indentation is inconsistent.",
}

TreeNode[] parseTrees(size_t indentationSize = 4)(string text)
{
    static assert(indentationSize > 0);

    auto lines = text.getNonEmptyLinesStrippedOfTrailingWhitespace().array();
    Appender!(TreeNode[]) trees;
    foreach (treeLines; splitRoots(lines))
    {
        auto tree = parseTreeLines!indentationSize(null, treeLines);
        trees.put(tree);
    }
    return trees.data;
}

private:

TreeNode parseTreeLines(size_t indentationSize)(TreeNode root, string[] lines)
{
    if (lines.empty)
        return null;

    bool firstLineBeginsWithWhitespace = isWhite(lines[0][0]);
    if (firstLineBeginsWithWhitespace)
        throw new Exception(Msg.rootIsIndented);

    auto node = new TreeNode(root, new UIObject(lines[0]));

    Appender!(TreeNode[]) children;
    auto lowerHierarchyLevel = lines[1 .. $].stripIndentation!indentationSize.array();
    foreach(lowerRoot; splitRoots(lowerHierarchyLevel))
        children.put(parseTreeLines!indentationSize(node, lowerRoot));

    node.children = children.data;
    return node;
}

// tree can't have multiple roots
unittest
{
    assertThrown(parseTreeLines!4(null, ["foo", "bar"]));
}

auto getNonEmptyLinesStrippedOfTrailingWhitespace(string s) pure
{
    import std.string;
    return s.splitLines().map!(a => a.stripRight()).filter!(a => !a.empty);
}

auto stripIndentation(size_t indentationSize, T)(T lines) pure nothrow
    if (isIterable!T && isSomeString!(ElementType!T))
{
    return lines.map!((a)
        {
            if (a.length < indentationSize || !isWhite(a[0 .. indentationSize]))
                throw new Exception(Msg.wrongIndentation);

            return a[indentationSize .. $];
        });
}

bool isWhite(string s) pure nothrow
{
    foreach(c; s)
        if (!c.isWhite())
            return false;

    return true;
}

string[][] splitRoots(string[] lines)
{
    Appender!(string[][]) app;
    auto rootIndices = getRootIndices(lines);
    if (!lines.empty && rootIndices.empty)
        throw new Exception(Msg.wrongIndentation);

    foreach (i; rootIndices.retro())
    {
        app.put(lines[i .. $]);
        lines = lines[0 .. i];
    }
    app.data.reverse();
    return app.data;
}

size_t[] getRootIndices(string[] lines)
{
    Appender!(size_t[]) app;
    foreach (i, line; lines)
    {
        bool isRoot = !isWhite(line[0]);
        if (isRoot)
            app.put(i);
    }
    return app.data;
}

version (unittest)
{
    import std.exception : assertThrown;
    bool isSoleNode(TreeNode n)
    {
        return (null is n.parent && n.children.empty);
    }

    TreeNode parseTree(size_t indentationSize = 4)(string text)
    {
        auto trees = parseTrees!indentationSize(text);
        if (null is trees)
            return null;

        assert(trees.length == 1);
        return trees[0];
    }
}

// empty input yields null
unittest
{
    auto root = parseTree(null);
    assert(null is root);

    root = parseTree("");
    assert(null is root);
}

// single line yields single node tree
unittest
{
    auto root = parseTree("foo");
    assert(root.isSoleNode());
    assert(0 == root.obj.namespace);
    assert("foo" == root.obj.id);
}

// trailing whitespaces are ignored
unittest
{
    auto root = parseTree("foo bar  \t \t\r\n");
    assert(root.isSoleNode());
    assert("foo bar" == root.obj.id);
}

// lines containing whitespaces are ignored
unittest
{
    auto root = parseTree(" \n  \n\t  \nfoo bar \n\t\r\n   \t ");
    assert(root.isSoleNode());
    assert("foo bar" == root.obj.id);
}

// tree root can't be indented
unittest
{
    assertThrown(parseTree(" foo"));
    assertThrown(parseTree("\tfoo"));
}

// two nodes yield a root with a single child
unittest
{
    auto root = parseTree("foo\n    bar");
    assert(null is root.parent);
    assert(1 == root.children.length);
    auto next = root.children[0];
    assert("bar" == next.obj.id);
    assert(root is next.parent);
    assert(next.children.empty);
}

// three nodes
unittest
{
    auto prev = parseTree!1("foo\n bar\n  fun");
    assert(1 == prev.children.length);
    auto next = prev.children[0];
    assert("bar" == next.obj.id);
    assert(prev is next.parent);
    assert(1 == next.children.length);
    prev = next;
    next = prev.children[0];
    assert("fun" == next.obj.id);
    assert(prev is next.parent);
    assert(next.children.empty);
}

// two children tree
unittest
{
    auto root = parseTree!1("foo\n bar\n fun");
    assert(2 == root.children.length);
}

version (unittest)
{
    void assertIdAndParent(TreeNode node, string id, TreeNode parent)
    {
        assert(id == node.obj.id);
        assert(parent is node.parent);
    }
}

unittest
{
    import std.conv : text;
    enum input = "
0
 00
  000
 01
  010
   0100
    01000
 02

1
 10
  100
  101
 11

2
 20
  200
  201

3";
    enum childrenCount = [3, 2, 1, 0];
    auto trees = parseTrees!1(input);
    assert(4 == trees.length);
    foreach (i, tree; trees)
    {
        tree.assertIdAndParent(i.text(), null);
        assert(childrenCount[i] == tree.children.length);
    }

    TreeNode temp;
    // tree 0
    temp = trees[0].children[0];
    temp.assertIdAndParent("00", trees[0]);
    assert(1 == temp.children.length);
    temp.children[0].assertIdAndParent("000", temp);
    assert(temp.children[0].children.empty);

    assert("01000" == trees[0].children[1].children[0].children[0].children[0].obj.id);

    // tree 2
    temp = trees[2].children[0];
    assert(2 == temp.children.length);
    temp.assertIdAndParent("20", trees[2]);

    temp.children[0].assertIdAndParent("200", temp);
    assert(temp.children[0].children.empty);
    temp.children[1].assertIdAndParent("201", temp);
    assert(temp.children[1].children.empty);
}
