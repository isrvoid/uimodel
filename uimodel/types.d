module uimodel.types;

abstract class UIObject
{
    string id;
}

class TreeNode : UIObject
{
    TreeNode parent;
    TreeNode[] children;
}
