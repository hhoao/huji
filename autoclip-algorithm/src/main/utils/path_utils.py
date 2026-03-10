from src import RESOURCES_PATH, ROOT_PATH


def path_join(*paths: str) -> str:
    clean_paths: list[str] = [path.strip("/") for path in paths if path]
    result: str = "/".join(clean_paths)
    if paths and paths[0].startswith("/") and paths[0] != "/":
        result = "/" + result
    return result


def get_resource(file: str) -> str:
    return path_join(RESOURCES_PATH, file)


def get_project_root_path(path: str) -> str:
    return path_join(ROOT_PATH, path)


def get_project_path(path: str) -> str:
    if path.startswith("$PROJECT_ROOT"):
        return get_project_root_path(path[len("$PROJECT_ROOT") :])
    if path.startswith("$PROJECT_RESOURCES"):
        return get_resource(path[len("$PROJECT_RESOURCES") :])
    return path
