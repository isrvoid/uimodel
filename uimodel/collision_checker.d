module uimodel.collision_checker;

@safe

class CollisionChecker
{
    private static CollisionChecker[string] checkers;

    private ubyte[uint] dict;

    private this() pure nothrow {}

    static CollisionChecker get(string name)() nothrow
    {
        CollisionChecker checker;
        auto p = name in checkers;
        if (p is null)
        {
            checker = makeDetached();
            checkers[name] = checker;
        }
        else
        {
            checker = *p;
        }
        return checker;
    }

    void put(uint hash) pure
    {
        import std.conv : text;
        auto p = hash in dict;
        if (p !is null)
            throw new Exception(hash.text() ~ " collides");

        dict[hash] = 0;
    }

    static auto makeDetached() pure nothrow
    {
        return new CollisionChecker();
    }
}

import std.exception;

unittest // get checker
{
    auto checker = CollisionChecker.get!"foo";
    assert(null !is checker);
    // same checker is returned for same name
    assert(checker is CollisionChecker.get!"foo");
    // different checker is returned for different name
    assert(checker !is CollisionChecker.get!"bar");
}

unittest // single value doesn't colide
{
    assertNotThrown(CollisionChecker.makeDetached().get!"foo".put(42));
}

unittest // same value collides
{
    auto checker = CollisionChecker.makeDetached();
    checker.put(42);
    assertThrown(checker.put(42));
}
