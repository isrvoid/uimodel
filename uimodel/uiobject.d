module uimodel.uiobject;

@safe:

class UIObject
{
    uint namespace;
    string id;

    this(string _id) pure nothrow
    {
        id = _id;
    }
}
