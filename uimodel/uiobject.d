module uimodel.uiobject;

@safe:

uint getFastHash(string id, uint namespace) pure nothrow
{
    import std.digest.sha;
    SHA1 sha;
    foreach (ubyte b; id)
        sha.put(b);

    foreach (i; 0 .. 4)
        sha.put(namespace >> 8 * i & 0xFF);

    return (cast(uint[]) sha.finish()[0 .. 4])[0];
}

class UIObject
{
    immutable
    {
        string id;
        uint namespace;
        uint fastHash;
    }

    this(string _id, uint _namespace = 0) pure nothrow
    {
        import uimodel.collision_checker;
        assert(_id.length);
        id = _id;
        namespace = _namespace;
        fastHash = getFastHash(_id, _namespace);
    }
}

interface Observer (T)
{
    void notify(T msg);
}

interface UpdateViewCommand (T)
{
    void execute(uint fastHash, T msg);
}

interface Command (T)
{
    void execute(T msg);
}

class UIView (T) : UIObject, Observer!T
{
    private UpdateViewCommand!T updateCommand;

    this(string _id, uint _namespace, UpdateViewCommand!T _updateCommand)
    {
        super(_id, _namespace);
        updateCommand = _updateCommand;
    }

    void notify(T msg)
    {
        updateCommand.execute(fastHash, msg);
    }
}

class UISignal (T) : UIObject, Command!T
{
    private Command!T command;

    this(string _id, uint _namespace, Command!T _command)
    {
        super(_id, _namespace);
        command = _command;
    }

    void execute(T msg)
    {
        try
        {
            command.execute(msg);
        }
        catch (Exception e)
        {
            // TODO log error
        }
    }
}

class UIControl (T) : UIView!T, Command!T
{
    private Command!T command;
    private T cache; // last view state to be received or successfully applied

    this(string _id, uint _namespace, UpdateViewCommand!T _update, Command!T _command)
    {
        super(_id, _namespace, _update);
        command = _command;
    }

    override void notify(T update)
    {
        bool shouldUpdate = cache != update || cache == T.init;
        if (!shouldUpdate)
            return;

        updateCommand.execute(fastHash, update);
        cache = update;
    }

    void execute(T msg)
    {
        // unlike view update, command call can't be optional
        try
        {
            scope(failure) notify(cache);
            command.execute(msg);
            cache = msg;
        }
        catch (Exception e)
        {
            // TODO log error
        }
    }
}

import std.exception : assertNotThrown;

unittest // empty name hash
{
    assertNotThrown(getFastHash(null, 0));
    assertNotThrown(getFastHash("", 42));
}

unittest // same hash is returned for input
{
    assert(getFastHash("foo", 42) == getFastHash("foo", 42));
}

unittest // different name yields different hash
{
    assert(getFastHash("foo", 0) != getFastHash("bar", 0));
}

unittest // different namespace yields different hash
{
    assert(getFastHash("foo", 0x8000) != getFastHash("foo", 0xC000));
}

// TODO refactor commands away, add tests:
// UIReadout update doesn't throw
// UISignal throws (use dummy setter)
// UIControl update follows recv error

unittest // create UIReadout
{
    auto foo = new UIView!double("foo", 0, null);
}

unittest // create UISignal
{
    auto signal = new UISignal!int("foo", 0, null);
}

unittest // create UIControl
{
    auto control = new UIControl!int("foo", 0, null, null);
}
