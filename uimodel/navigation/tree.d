module uimodel.navigation.tree;

import uimodel.uiobject;

@safe:

class TreeNode (T)
{
    TreeNode parent;
    TreeNode[] children;

    T obj;
    alias obj this;

    this(TreeNode _parent, T _obj)
    {
        parent = _parent;
        obj = _obj;
    }
}
