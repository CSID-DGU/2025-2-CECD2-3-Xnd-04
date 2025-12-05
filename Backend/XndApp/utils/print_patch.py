import builtins
_original_print = builtins.print

def patched_print(*args, **kwargs):
    kwargs["flush"] = True
    _original_print(*args, **kwargs)

builtins.print = patched_print