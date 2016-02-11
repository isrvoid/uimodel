module uimodel.types;

class UIObject
{
    uint namespace;
    string id;
}

class TreeNode
{
    TreeNode parent;
    TreeNode[] children;

    UIObject obj;
}
