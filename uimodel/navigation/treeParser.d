module uimodel.navigation.tree_parser;

import std.range.primitives : empty, front;
import std.algorithm : map;
import std.traits;
import std.range : ElementType;
import std.uni : isWhite;

import uimodel.uiobject;
import uimodel.navigation.tree;

@safe:

private enum Msg : string
{
    rootIsIndented = "Tree root must be at the beginning of the line.",
    wrongIndentation = "Indentation is inconsistent.",
}

//TreeNode[] parseForest(string forest)
//{ }

TreeNode parseTree(size_t indentCharCount = 4)(string tree)
{
    static assert(indentCharCount > 0);

    auto lines = tree.getNonEmptyLinesStrippedOfTrailingWhitespace();
    if (lines.empty)
        return null;

    auto firstLine = lines.front;
    if (firstLine.front.isWhite())
        throw new Exception(Msg.rootIsIndented);

    auto res = new TreeNode(new UIObject(firstLine));

    lines.popFront();
    if (!lines.empty)
    {
        // FIXME
        auto newRoots = lines.stripIndentation!(indentCharCount);
        res.children ~= parseTree!indentCharCount(newRoots.front);
    }
    return res;
}

private auto getNonEmptyLinesStrippedOfTrailingWhitespace(string s) pure
{
    import std.algorithm : filter;
    import std.string;
    return s.splitLines().map!(a => a.stripRight()).filter!(a => !a.empty);
}

private auto stripIndentation(size_t indentCharCount, T)(T lines) pure nothrow
    if (isIterable!T && isSomeString!(ElementType!T))
{
    return lines.map!((a) {
            if (a.length < indentCharCount || !isWhite(a[0 .. indentCharCount]))
                throw new Exception(Msg.wrongIndentation);

            return a[indentCharCount .. $]; });
}

private bool isWhite(string s) pure nothrow
{
    foreach(c; s)
        if (!c.isWhite())
            return false;

    return true;
}

version (unittest)
{
    import std.exception : assertThrown;
    bool isSoleNode(TreeNode n)
    {
        return (null is n.parent && n.children.empty);
    }

    unittest
    {
        assert(new TreeNode(null).isSoleNode());
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

// tree can't have multiple roots
unittest
{
    assertThrown(parseTree("foo\nbar"));
}

// two nodes yield a root with a single child
unittest
{
    auto root = parseTree("foo\n    bar");
    assert(null is root.parent);
    assert(1 == root.children.length);
    auto next = root.children[0];
    assert("bar" == next.obj.id);
    //assert(root is next.parent); // FIXME
    assert(next.children.empty);
}

// three nodes
unittest
{
    auto prev = parseTree!1("foo\n bar\n  fun");
    assert(1 == prev.children.length);
    auto next = prev.children[0];
    assert("bar" == next.obj.id);
    // FIXME
    /*
    assert(prev is next.parent);
    assert(1 == next.children.length);
    prev = next;
    next = prev.children[0];
    assert("fun" == next.obj.id);
    assert(prev is next.parent);
    assert(next.children.empty);
    */
}
