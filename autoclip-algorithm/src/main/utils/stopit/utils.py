"""
============
stopit.utils
============

Misc utilities and common resources
"""

import functools
import logging
from collections.abc import Callable
from typing import Any


# Custom LOG
LOG = logging.getLogger(name="stopit")


class NullHandler(logging.Handler):
    def emit(self, record: Any) -> None:
        pass


class TimeoutExceptionError(Exception):
    """Raised when the block under context management takes longer to complete
    than the allowed maximum timeout value.
    """

    pass


class BaseTimeout:
    """Context manager for limiting in the time the execution of a block

    :param seconds: ``float`` or ``int`` duration enabled to run the context
      manager block
    :param swallow_exc: ``False`` if you want to manage the
      ``TimeoutExceptionError`` (or any other) in an outer ``try ... except``
      structure. ``True`` (default) if you just want to check the execution of
      the block with the ``state`` attribute of the context manager.
    """

    # Possible values for the ``state`` attribute, self explanative
    EXECUTED, EXECUTING, TIMED_OUT, INTERRUPTED, CANCELED = range(5)

    def __init__(self, seconds: float, swallow_exc: bool = True) -> None:
        self.seconds = seconds
        self.swallow_exc = swallow_exc
        self.state = BaseTimeout.EXECUTED

    def __bool__(self) -> bool:
        return self.state in (
            BaseTimeout.EXECUTED,
            BaseTimeout.EXECUTING,
            BaseTimeout.CANCELED,
        )

    __nonzero__ = __bool__  # Python 2.x

    def __repr__(self) -> str:
        """Debug helper"""
        return f"<{self.__class__.__name__} in state: {self.state}>"

    def __enter__(self) -> "BaseTimeout":
        self.state = BaseTimeout.EXECUTING
        self.setup_interrupt()
        return self

    def __exit__(
        self, exc_type: type[Exception] | None, exc_val: Exception | None, exc_tb: Any
    ) -> bool:
        if exc_type is TimeoutExceptionError:
            if self.state != BaseTimeout.TIMED_OUT:
                self.state = BaseTimeout.INTERRUPTED
                self.suppress_interrupt()
            LOG.warning(
                f"Code block execution exceeded {self.seconds} seconds timeout",
                exc_info=(exc_type, exc_val, exc_tb),  # type: ignore
            )
            return self.swallow_exc
        if exc_type is None:
            self.state = BaseTimeout.EXECUTED
        self.suppress_interrupt()
        return False

    def cancel(self) -> None:
        """In case in the block you realize you don't need anymore
        limitation"""
        self.state = BaseTimeout.CANCELED
        self.suppress_interrupt()

    # Methods must be provided by subclasses
    def suppress_interrupt(self) -> None:
        """Removes/neutralizes the feature that interrupts the executed block"""
        raise NotImplementedError

    def setup_interrupt(self) -> None:
        """Installs/initializes the feature that interrupts the executed block"""
        raise NotImplementedError


class base_timeoutable(object):  # noqa
    """A base for function or method decorator that raises a ``TimeoutExceptionError`` to
    decorated functions that should not last a certain amount of time.

    Any decorated callable may receive a ``timeout`` optional parameter that
    specifies the number of seconds allocated to the callable execution.

    The decorated functions that exceed that timeout return ``None`` or the
    value provided by the decorator.

    :param default: The default value in case we timed out during the decorated
      function execution. Default is None.

    :param timeout_param: As adding dynamically a ``timeout`` named parameter
      to the decorated callable may conflict with the callable signature, you
      may choose another name to provide that parameter. Your decoration line
      could look like ``@timeoutable(timeout_param='my_timeout')``

    .. note::

       This is a base class that must be subclassed. subclasses must override
       thz ``to_ctx_mgr`` with a timeout  context manager class which in turn
       must subclasses of above ``BaseTimeout`` class.
    """

    to_ctx_mgr: type[BaseTimeout] | None = None

    def __init__(self, default: Any = None, timeout_param: str = "timeout") -> None:
        self.default: Any = default
        self.timeout_param: str = timeout_param

    def __call__(self, func: Callable[..., Any]) -> Callable[..., Any]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            timeout: int | None = kwargs.pop(self.timeout_param, None)
            if timeout:
                with self.to_ctx_mgr(timeout, swallow_exc=True):  # type: ignore
                    result: Any = self.default
                    # ``result`` may not be assigned below in case of timeout
                    result = func(*args, **kwargs)
                return result  # type: ignore
            return func(*args, **kwargs)

        return wrapper
