module uimodel.types;

class UIObject
{
    uint namespaceIndex;
    string id;
}

class TreeNode
{
    TreeNode parent;
    TreeNode[] children;

    UIObject obj;
}
