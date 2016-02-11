module uimodel.navigation.tree_parser;

import std.range.primitives : empty, front;
import std.algorithm : map;
import std.traits;
import std.exception : assertThrown, enforce;
import std.string;
import std.range;
import std.uni : isWhite;

import uimodel.uiobject;
import uimodel.navigation.tree;

@safe:

private enum Msg : string
{
    indentedRoot = "Tree root must be at the beginning of the line.",
    wrongIndentation = "Indentation is inconsistent.",
}

//TreeNode[] parseForest(string forest)
//{ }

TreeNode parseTree(uint indent = 4)(string tree)
{
    static assert(indent > 0);

    import std.array : array;
    auto lines = tree.getNonEmptyLinesStrippedOfTrailingWhitespace().array();
    if (lines.empty)
        return null;

    auto firstLine = lines.front;
    if (firstLine.front.isWhite())
        throw new Exception(Msg.indentedRoot);

    lines.popFront();
    if (!lines.empty)
        lines.stripIndent!indent;

    return new TreeNode(new UIObject(firstLine));
}

private auto getNonEmptyLinesStrippedOfTrailingWhitespace(string s) pure
{
    import std.algorithm : filter;
    return s.splitLines().map!(a => a.stripRight()).filter!(a => !a.empty);
}

private void stripIndent(uint indent)(string[] lines)
{
    foreach(ref line; lines)
    {
        if (line.length < indent || !isWhite(line[0 .. indent]))
            throw new Exception(Msg.wrongIndentation);

        line = line[indent .. $];
    }
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

// two nodes yields a root with a single child
unittest
{
    auto root = parseTree("foo\n    bar");
    assert(null is root.parent);
    // FIXME
    //assert
}


/* XXX
parseForest
    splitAtNotches
        loop: parseTree

indentation rule should be determined for each tree to make it less strict
 */
