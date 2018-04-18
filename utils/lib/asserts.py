#!/usr/bin/env python3
def __safe_call(f, a):
    """Call a function and capture all exceptions."""
    try:
        return f(a)
    except Exception as e:
        return "{}@{}({})".format(a.__class__.__name__, id(a), e)

def __safe_error(msg, a, b):
    """Generate the error message for assert_XX without causing an error."""
    return "{} ({}) {} {} ({})".format(
        __safe_call(str, a), __safe_call(repr, a),
        msg,
        __safe_call(str, b), __safe_call(repr, b),
    )

def assert_eq(a, b):
    """Assert equal with better error message."""
    assert a == b, __safe_error("!=", a, b)

def assert_is(a, b):
    """Assert is with better error message."""
    assert a is b, __safe_error("is not", a, b)

def assert_type(obj, cls, msg="{obj} ({obj!r}) should be a {cls}, not {objcls}"):
    """Raise a type error if obj is not an instance of cls."""
    if not isinstance(obj, cls):
        raise TypeError(msg.format(obj=obj, objcls=type(obj), cls=cls))

def assert_type_or_none(obj, classes):
    """Raise a type error if obj is not an instance of cls or None."""
    if obj is not None:
        assert_type(obj, classes)

def assert_len_eq(l):
    """Check all lists in a list are equal length"""
    # Sanity check
    max_len = max(len(p) for p in l)
    for i, p in enumerate(l):
        assert len(p) == max_len, "Length check failed!\nl[{}] has {} elements != {} ({!r})\n{!r}".format(
            i, len(p), max_len, p, l)
