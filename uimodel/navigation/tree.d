module uimodel.navigation.tree;

import uimodel.uiobject;

@safe:

class TreeNode
{
    TreeNode parent;
    TreeNode[] children;

    UIObject obj;

    this() { }

    this(UIObject _obj, TreeNode _parent = null, TreeNode[] _children = null)
    {
        obj = _obj;
        parent = _parent;
        children = _children;
    }
}
