module uimodel.uiobject;

@safe:

class UIObject
{
    uint namespace;
    string id;

    this(string _id, uint _namespace = 0) pure nothrow
    {
        namespace = _namespace;
        id = _id;
    }
}

class UIView (T) : UIObject, Observer!T
{
    private UpdateViewCommand!T command;

    this(string _id, uint _namespace, UpdateViewCommand!T _command)
    {
        super(_id, _namespace);
        command = _command;
    }

    void notify(T update)
    {
        command.executeViewUpdate(this, update);
    }
}

interface Observer (T)
{
    void notify(T msg);
}

class UISignal (T) : UIObject
{
    void function(T) execute;

    this(string _id, uint _namespace, void function(T) _execute)
    {
        super(id, _namespace);
        execute = _execute;
    }
}

interface UpdateViewCommand (T)
{
    void executeViewUpdate(UIView!T view, T update);
}

class UIControl (T) : UIView
{
    void function(T) execute;

    this(string _id, uint _namespace, void function(T) _execute)
    {
        super(id, _namespace);
        execute = _execute;
    }
}

unittest // simple UIView creation
{
    auto view = new UIView!double(null, 0, null);
}
