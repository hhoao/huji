def is_empty(text: str | None) -> bool:
    return text is None or len(text) == 0


def is_not_empty(text: str | None) -> bool:
    return not is_empty(text)


def is_blank(text: str | None) -> bool:
    return text is None or len(text.strip()) == 0


def is_not_blank(text: str | None) -> bool:
    return not is_blank(text)


def default_if_empty(text: str | None, default: str) -> str:
    return default if is_empty(text) else text or default


def default_if_blank(text: str | None, default: str) -> str:
    return default if is_blank(text) else text or default
