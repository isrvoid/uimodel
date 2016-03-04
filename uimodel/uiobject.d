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

interface Receiver (T)
{
    void receive(T msg);
}

alias sendFunc (T) = void function(uint fastHash, T msg);
alias recvFunc (T) = void function(T msg);

class UIView (T) : UIObject, Observer!T
{
    private T cache; // last view state to be received or successfully applied

    sendFunc!T send;

    this(string _id, uint _namespace, sendFunc!T _send)
    {
        super(_id, _namespace);
        send = _send;
    }

    void notify(T update)
    {
        bool shouldUpdate = cache != update || cache == T.init;
        if (!shouldUpdate)
            return;

        send(fastHash, update);
        cache = update;
    }
}

class UISignal (T) : UIObject, Receiver!T
{
    recvFunc!T recv;

    this(string _id, uint _namespace, recvFunc!T _recv)
    {
        super(_id, _namespace);
        recv = _recv;
    }

    void receive(T msg)
    {
        try
        {
            recv(msg);
        }
        catch (Exception e)
        {
            // TODO log error
        }
    }
}

class UIControl (T) : UIView!T, Receiver!T
{
    recvFunc!T recv;

    this(string _id, uint _namespace, sendFunc!T _send, recvFunc!T _recv)
    {
        super(_id, _namespace, _send);
        recv = _recv;
    }

    void receive(T msg)
    {
        // unlike view update, recv call can't be optional
        try
        {
            scope(failure) notify(cache);
            recv(msg);
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
