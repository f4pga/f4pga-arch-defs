def assert_eq(a, b):
    assert a == b, "{} ({}) != {} ({})".format(a, repr(a), b, repr(b))

def assert_type(obj, cls, msg="{obj} ({obj!} should be a {cls}, not {objcls}"):
    """Raise a type error if obj is not an instance of cls."""
    if not isinstance(obj, cls):
        raise TypeError(msg.format(obj=obj, objcls=type(obj), cls=cls))

def assert_len_eq(l):
    """Check all lists in a list are equal length"""
    # Sanity check
    max_len = max(len(p) for p in l)
    for i, p in enumerate(l):
        assert len(p) == max_len, "Length check failed!\nl[{}] has {} elements != {} ({!r})\n{!r}".format(
            i, len(p), max_len, p, l)
