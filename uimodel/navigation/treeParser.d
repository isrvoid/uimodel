module uimodel.navigation.tree_parser;

import std.range.primitives : empty;
import std.algorithm : map;

import uimodel.uiobject;
import uimodel.navigation.tree;

@safe:
// XXX remember ID namespace (prefix) to reduce clutter

//TreeNode[string] parseForest(string forest)
//{ }

TreeNode parseTree(string tree)
{
    auto lines = tree.getNonEmptyLinesStrippedOfTrailingWhitespace();
    if (lines.empty)
        return null;

    return new TreeNode(new UIObject(lines.front));
}

private auto getNonEmptyLinesStrippedOfTrailingWhitespace(string s) pure
{
    import std.string;
    import std.algorithm : filter;
    return s.splitLines().map!(a => a.stripRight()).filter!(a => !a.empty);
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



/* XXX
parseForest
    splitAtNotches
        loop:
        popTreeName
        parseTree

indentation rule is determined for each tree to make it less strict
 */
