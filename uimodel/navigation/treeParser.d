module uimodel.navigation.tree_parser;

import uimodel.types;

// XXX remember ID namespace (prefix) to reduce clutter

//TreeNode[string] parseForest(string forest)
//{ }

TreeNode parseTree(string tree)
{
    return null;
}

// empty input yields null
unittest
{
    auto root = parseTree(null);
    assert(null == root);

    root = parseTree("");
    assert(null == root);

    root = parseTree(" \t\t\n  \r\n  \n");
    assert(null == root);
}

/* XXX
parseForest
    splitAtNotches
        loop:
        popTreeName
        parseTree

indentation rule is determined for each tree to make it less strict
 */
