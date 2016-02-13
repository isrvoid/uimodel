module uimodel.navigation.tree_parser;

import std.algorithm;
import std.range : empty, retro;
import std.uni : isWhite;
import std.array : array, Appender;

import uimodel.uiobject;
import uimodel.navigation.tree;
alias UITreeNode = TreeNode!UIObject;

@safe:

UITreeNode[] parseTrees(string text)
{
    auto lines = text.normalizeAndVerifyInput();
    Appender!(UITreeNode[]) trees;
    foreach (treeLines; splitRoots(lines))
    {
        auto tree = parseTree(null, treeLines);
        trees.put(tree);
    }
    return trees.data;
}

class TreeParserException : Exception
{
    this(Msg msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure nothrow @nogc
    {
        super(msg, file, line, next);
    }

    enum Msg : string
    {
        rootMissing = "First line can't be indented (highest hierarchy level).",
        hierarchyError = "Input results in invalid hierarchy."
    }
}
alias Msg = TreeParserException.Msg;

private:

UITreeNode parseTree(UITreeNode root, string[] lines)
{
    if (lines.empty)
        return null;

    assert(!lines[0][0].isWhite());
    auto node = new UITreeNode(root, new UIObject(lines[0]));
    lines = lines[1 .. $];
    // lower hierarchy level by popping front chars
    lines.each!((ref a) => a = a[1 .. $]);

    Appender!(UITreeNode[]) children;
    foreach(lowerRoot; splitRoots(lines))
        children.put(parseTree(node, lowerRoot));

    node.children = children.data;
    return node;
}

string[] normalizeAndVerifyInput(string s) pure
{
    auto lines = s.getNonEmptyLinesStrippedOfTrailingWhitespace().array();
    lines = normalizeIndentation(lines);
    verifyHierarchy(lines);
    return lines;
}

auto getNonEmptyLinesStrippedOfTrailingWhitespace(string s) pure
{
    import std.string;
    return s.splitLines().map!(a => a.stripRight()).filter!(a => !a.empty);
}

/*
   TODO
   - move to util
   - Feature: Add check for whitespace characters consistency.
     Whitespaces are considered equal and counted as 1 -- potentially deceptive.
*/
string[] normalizeIndentation(string[] _lines) pure
in
{
    foreach (line; _lines)
        assert(line.hasNonWhitespaceChar());
}
body
{
    auto lines = _lines.dup;
    auto indentSizes = lines.map!(a => a.getLeadingWhitespaceCount()).array();
    auto nonZeroIndentSizes = indentSizes.filter!(a => a > 0);
    auto minNonZeroIndentSize = reduce!min(size_t.max, nonZeroIndentSizes);
    alias normDivider = minNonZeroIndentSize;
    foreach (i, ref line; lines)
    {
        auto indentSize = indentSizes[i];
        if (indentSize % normDivider)
            throw new Exception("Indentation is inconsistent.");

        auto newIndentSize = indentSize / normDivider;
        line = line[indentSize - newIndentSize .. $];
    }
    return lines;
}

size_t getLeadingWhitespaceCount(string s) pure nothrow
{
    foreach (i, c; s)
        if (!c.isWhite())
            return i;

    return s.length;
}

unittest // empty input yields null
{
    assert(null is normalizeIndentation(null));
    assert(null is normalizeIndentation([]));
}

unittest // unindented input is left unchanged
{
    enum lines = ["foo", "bar"];
    assert(lines == normalizeIndentation(lines));
}

unittest // normalized indentation is left unchanged
{
    enum lines = [" foo", "bar", "   fun"];
    assert(lines == normalizeIndentation(lines));
}

unittest // simple normalization
{
    assert([" foo"] == normalizeIndentation(["    foo"]));
    assert([" foo", "bar", "  fun"] == normalizeIndentation(["   foo", "bar", "      fun"]));
}

unittest // inconsistent indentation error
{
    assertThrown(normalizeIndentation(["  foo", "   bar"]));
    assertThrown(normalizeIndentation(["    foo", "     bar", "  fun"]));
}

bool hasNonWhitespaceChar(string s) pure nothrow
{
    foreach (c; s)
        if (!c.isWhite())
            return true;

    return false;
}

void verifyHierarchy(in string[] lines) pure
{
    if (lines.empty)
        return;

    auto levels = lines.map!(a => cast(uint) a.getLeadingWhitespaceCount()).array();
    if (levels[0] != 0)
        throw new TreeParserException(Msg.rootMissing);
    levels = levels[1 .. $];

    uint prevLevel = 0;
    foreach (level; levels)
    {
        int diff = level - prevLevel;
        if (diff > 1)
            throw new TreeParserException(Msg.hierarchyError);

        prevLevel = level;
    }
}

string[][] splitRoots(string[] lines)
{
    if (lines.empty)
        return null;

    auto rootIndices = getRootIndices(lines);
    Appender!(string[][]) app;
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
    bool isSoleNode(UITreeNode n)
    {
        return (null is n.parent && n.children.empty);
    }

    UITreeNode parseTree(string text)
    {
        auto trees = parseTrees(text);
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
    assert(0 == root.namespace);
    assert("foo" == root.id);
}

// trailing whitespaces are ignored
unittest
{
    auto root = parseTree("foo bar  \t \t\r\n");
    assert(root.isSoleNode());
    assert("foo bar" == root.id);
}

// lines containing whitespaces are ignored
unittest
{
    auto root = parseTree(" \n  \n\t  \nfoo bar \n\t\r\n   \t ");
    assert(root.isSoleNode());
    assert("foo bar" == root.id);
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
    assert("bar" == next.id);
    assert(root is next.parent);
    assert(next.children.empty);
}

// three nodes
unittest
{
    auto prev = parseTree("foo\n bar\n  fun");
    assert(1 == prev.children.length);
    auto next = prev.children[0];
    assert("bar" == next.id);
    assert(prev is next.parent);
    assert(1 == next.children.length);
    prev = next;
    next = prev.children[0];
    assert("fun" == next.id);
    assert(prev is next.parent);
    assert(next.children.empty);
}

// two children tree
unittest
{
    auto root = parseTree("foo\n bar\n fun");
    assert(2 == root.children.length);
}

// hierarchy error
unittest
{
    assertThrown(parseTrees(" foo"));
    assertThrown(parseTrees(" foo\nbar"));
    assertThrown(parseTrees("foo\n  bar\n fun"));
}

version (unittest)
{
    void assertIdAndParent(UITreeNode node, string id, UITreeNode parent)
    {
        assert(id == node.id);
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
    auto trees = parseTrees(input);
    assert(4 == trees.length);
    foreach (i, tree; trees)
    {
        tree.assertIdAndParent(i.text(), null);
        assert(childrenCount[i] == tree.children.length);
    }

    UITreeNode temp;
    // tree 0
    temp = trees[0].children[0];
    temp.assertIdAndParent("00", trees[0]);
    assert(1 == temp.children.length);
    temp.children[0].assertIdAndParent("000", temp);
    assert(temp.children[0].children.empty);

    assert("01000" == trees[0].children[1].children[0].children[0].children[0].id);

    // tree 2
    temp = trees[2].children[0];
    assert(2 == temp.children.length);
    temp.assertIdAndParent("20", trees[2]);

    temp.children[0].assertIdAndParent("200", temp);
    assert(temp.children[0].children.empty);
    temp.children[1].assertIdAndParent("201", temp);
    assert(temp.children[1].children.empty);
}
