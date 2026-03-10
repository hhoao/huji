"""
=================
stopit.signalstop
=================

Control the timeout of blocks or callables with a context manager or a
decorator. Based on the use of signal.SIGALRM
"""

import signal
from typing import Any

from .utils import BaseTimeout, TimeoutExceptionError, base_timeoutable


class SignalTimeout(BaseTimeout):
    """Context manager for limiting in the time the execution of a block
    using signal.SIGALRM Unix signal.

    See :class:`stopit.utils.BaseTimeout` for more information
    """

    def __init__(self, seconds: float, swallow_exc: bool = True) -> None:
        self._seconds = int(seconds)  # alarm delay for signal MUST be int
        super().__init__(self._seconds, swallow_exc)

    def handle_timeout(self, signum: int, frame: Any) -> None:
        self.state = BaseTimeout.TIMED_OUT
        raise TimeoutExceptionError(
            f"Block exceeded maximum timeout value ({self._seconds} seconds)."
        )

    # Required overrides
    def setup_interrupt(self) -> None:
        signal.signal(signal.SIGALRM, self.handle_timeout)
        signal.alarm(self._seconds)

    def suppress_interrupt(self) -> None:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, signal.SIG_DFL)


class signal_timeoutable(base_timeoutable):  # noqa
    """A function or method decorator that raises a ``TimeoutExceptionError`` to
    decorated functions that should not last a certain amount of time.
    this one uses ``SignalTimeout`` context manager.

    See :class:`.utils.base_timoutable`` class for further comments.
    """

    to_ctx_mgr: type[BaseTimeout] | None = SignalTimeout
