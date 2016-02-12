module uimodel.navigation.tree;

import uimodel.uiobject;

@safe:

class TreeNode
{
    TreeNode parent;
    TreeNode[] children;

    UIObject obj;

    this(TreeNode _parent, UIObject _obj)
    {
        parent = _parent;
        obj = _obj;
    }
}
