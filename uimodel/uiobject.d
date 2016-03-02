module uimodel.uiobject;

@safe:

class UIObject
{
    string id;
    uint namespace;

    this(string _id, uint _namespace = 0) pure nothrow
    {
        namespace = _namespace;
        id = _id;
    }
}

class UIView (T) : UIObject, Observer!T
{
    private UpdateViewCommand!T updateView;

    this(string _id, uint _namespace, UpdateViewCommand!T _updateView)
    {
        super(_id, _namespace);
        updateView = _updateView;
    }

    void notify(T update)
    {
        updateView.execute(this, update);
    }
}

interface Observer (T)
{
    void notify(T msg);
}

interface Command (T)
{
    void execute(T msg);
}

class UISignal (T) : UIObject, Command!T
{
    private Command!T command;

    this(string _id, uint _namespace, Command!T _command)
    {
        super(id, _namespace);
        command = _command;
    }

    void execute(T msg)
    {
        command.execute(msg);
    }
}

interface UpdateViewCommand (T)
{
    void execute(UIView!T view, T update);
}

class UIControl (T) : UIView!T, Command!T
{
    private Command!T command;

    this(string _id, uint _namespace, UpdateViewCommand!T _updateView, Command!T _command)
    {
        super(id, _namespace, _updateView);
        command = _command;
    }

    void execute(T msg)
    {
        command.execute(msg);
    }
}

unittest // create UIView
{
    auto view = new UIView!double(null, 0, null);
}

unittest // create UISignal
{
    auto signal = new UISignal!int(null, 0, null);
}

unittest // create UIControl
{
    auto control = new UIControl!int(null, 0, null, null);
}
