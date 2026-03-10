import concurrent
import concurrent.futures
import logging
import os
import shutil
import threading
import time
from collections.abc import Callable, Generator
from concurrent.futures import ProcessPoolExecutor
from contextlib import contextmanager
from typing import Any, cast

import tenacity

from src.main.logger import LOG
from src.main.utils.stopit import ThreadingTimeout


@contextmanager
def timer(*key: str) -> Generator[None]:
    formatted_keys: str = " ".join(f"[{element}]" for element in key)
    start: float = time.perf_counter()
    LOG.info(f"{formatted_keys} 开始.....")
    yield
    LOG.info(f"{formatted_keys} 耗时: {time.perf_counter() - start:.2f} 秒。")


def has_key_value(format_data: dict[str, Any], field: Any) -> bool:
    return field.f_name in format_data and format_data[field.f_name] is not None


def has_key(format_data: dict[str, Any], key: str) -> bool:
    return key in format_data and format_data[key] is not None


class BlockingProcessPoolExecutor(ProcessPoolExecutor):
    def __init__(self, max_workers: int | None = None) -> None:
        super().__init__(max_workers)
        self.semaphore: threading.Semaphore = threading.Semaphore(max_workers or 1)

    def submit[T](
        self, fn: Callable[..., T], *args: Any, **kwargs: Any
    ) -> concurrent.futures.Future[T]:
        self.semaphore.acquire()
        future: concurrent.futures.Future[T] = super().submit(fn, *args, **kwargs)
        future.add_done_callback(lambda _: self.semaphore.release())
        return future


def split_array(arr: list[Any], n: int) -> list[list[Any]]:
    length: int = len(arr)
    k: int
    r: int
    k, r = divmod(length, n)
    result: list[list[Any]] = []
    start: int = 0
    for i in range(n):
        current_length: int = k + 1 if i < r else k
        end: int = start + current_length
        result.append(arr[start:end])
        start = end
    return result


def delete_path(path: str) -> None:
    if os.path.isdir(path):
        shutil.rmtree(path)
    else:
        os.remove(path)


def retry_all_methods[T](cls: type[T]) -> type[T]:
    retry_decorator = tenacity.retry(
        stop=tenacity.stop_after_attempt(3),
        wait=tenacity.wait_fixed(2),
        reraise=True,
        before_sleep=tenacity.before_sleep_log(cast(logging.Logger, LOG), logging.INFO),
    )
    for name, method in cls.__dict__.items():
        if callable(method):
            setattr(cls, name, retry_decorator(method))
    return cls


def timeout_retry_all_methods[T](
    max_retries: int = 3, timeout: int = 180
) -> Callable[[type[T]], type[T]]:
    def class_decorator(cls: type[T]) -> type[T]:
        for name, method in cls.__dict__.items():
            if callable(method) and not name.startswith("__"):
                setattr(cls, name, timeout_retry(max_retries, timeout)(method))
        return cls

    return class_decorator


def timeout_exec[T](func: Callable[..., T], timeout: int, *args: Any, **kwargs: Any) -> T:  # type: ignore
    with ThreadingTimeout(timeout) as timeout_ctx:
        if timeout_ctx.state == timeout_ctx.TIMED_OUT:
            raise TimeoutError(f"方法 {func.__name__} 超时")
        return func(*args, **kwargs)


class CompletableFuture:
    def __init__(self) -> None:
        self._result: Any = None
        self._is_done: bool = False
        self._lock: threading.Lock = threading.Lock()
        self._condition: threading.Condition = threading.Condition(self._lock)

    def supply_async[T](
        self, func: Callable[..., T], *args: Any, **kwargs: Any
    ) -> "CompletableFuture":
        def target() -> None:
            result: T = func(*args, **kwargs)
            with self._condition:
                self._result = result
                self._is_done = True
                self._condition.notify_all()

        thread: threading.Thread = threading.Thread(target=target)
        thread.daemon = True
        thread.start()
        return self

    def then_apply[T](self, func: Callable[[Any], T]) -> "CompletableFuture":
        result: Any = self.result()
        new_future: CompletableFuture = CompletableFuture()
        new_future.supply_async(func, result)
        return new_future

    def result(self, timeout: float | None = None) -> Any:
        with self._condition:
            if not self._is_done:
                self._condition.wait(timeout)
            if not self._is_done:
                raise TimeoutError("Operation timed out")
            return self._result


def timeout_retry[T](
    max_retries: int = 3, timeout: int = 60
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """
    超时重试装饰器
    :param max_retries: 最大重试次数
    :param timeout: 超时时间（秒）
    """

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        def wrapper(*args: Any, **kwargs: Any) -> T:
            retries: int = 0
            while retries < max_retries:
                try:
                    future: CompletableFuture = CompletableFuture().supply_async(
                        timeout_exec, *(func, timeout, *args), **kwargs
                    )
                    return cast(T, future.result(timeout))
                except (TimeoutError, concurrent.futures.TimeoutError):
                    retries += 1
                    LOG.warning(f"超时重试 {retries}/{max_retries}")
                except Exception as e:
                    raise e
            raise TimeoutError(f"方法 {func.__name__} 在 {max_retries} 次重试后仍超时")

        return wrapper

    return decorator


def retry_with_timeout[T](
    func: Callable[..., T],
    *args: Any,
    timeout: float = 30,
    max_retries: int = 3,
    **kwargs: Any,
) -> T:
    retries = 0
    while retries < max_retries:
        try:
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(func, *args, **kwargs)
                return future.result(timeout)
        except (TimeoutError, concurrent.futures.TimeoutError):
            retries += 1
            LOG.warning(f"超时重试 {retries}/{max_retries}")
        except Exception as e:
            raise e
    raise TimeoutError(f"Function {func.__name__} timed out after {max_retries} retries")
