import json
from http.client import HTTPException
from typing import Any

import httpx
from httpx import BaseTransport, Client, Request, Response

from src.main.config.config import InternalHttpConfig
from src.main.utils import json_utils, string_utils


class ResponseModifier(BaseTransport):
    def __init__(self, transport: BaseTransport, http_client: "InternalHttp") -> None:
        self._transport = transport
        self.http: InternalHttp = http_client

    def handle_request(self, request: Request) -> Response:
        if request.method == "GET":
            # For GET requests, convert query parameters to camel case
            params = dict(request.url.params)
            camel_params = json_utils.convert_keys_to_camel(params)
            new_request = httpx.Request(
                method=request.method, url=request.url.copy_with(params=camel_params)
            )
        else:
            # For other methods, convert body to camel case
            new_content = json.dumps(
                json_utils.convert_keys_to_camel(json.loads(str(request.content, encoding="utf-8")))
            ).encode("utf-8")
            new_request = httpx.Request(method=request.method, url=request.url, content=new_content)

        # Copy headers except content-length
        for header in request.headers:
            if header.lower() != "content-length":
                new_request.headers[header] = request.headers[header]
        new_request.headers["tenant-id"] = "1"

        if string_utils.is_not_empty(self.http.access_token):
            new_request.headers["Authorization"] = self.http.access_token

        res: Response = self._transport.handle_request(new_request)
        if res.status_code == 200:
            res.read()
            body: dict[str, Any] = res.json()
            if body["code"] == 0:
                # Convert response data from camel case to snake case
                snake_case_data = json_utils.convert_keys_to_snake(body["data"])
                return httpx.Response(
                    status_code=body["code"],
                    headers=res.headers,
                    content=json.dumps(snake_case_data).encode("utf-8"),
                )
            raise HTTPException(f"Http request failed, msg: {body['msg']}, code: {body['code']}")
        return res


class Http:
    def __init__(self, client: Client) -> None:
        self.client: Client = client


class InternalHttp(Http):
    access_token: str

    def __init__(self, config: InternalHttpConfig) -> None:
        super().__init__(
            httpx.Client(
                base_url=config.base_url,
                transport=ResponseModifier(httpx.HTTPTransport(), self),
                event_hooks={"response": [], "new_request": []},
            )
        )
        self.access_token: str = config.access_token


class AlwaysSuccessHttp(Http):
    def __init__(self, config: InternalHttpConfig) -> None:
        super().__init__(
            httpx.Client(
                base_url=config.base_url,
                transport=AlwaysSuccessTransport(),
                event_hooks={"response": [], "new_request": []},
            )
        )
        self.access_token: str = config.access_token


class AlwaysSuccessTransport(BaseTransport):
    def handle_request(self, request: Request) -> Response:
        return httpx.Response(
            status_code=200,
            headers={},
            content=json.dumps({"code": 0, "msg": "success", "data": {}}).encode("utf-8"),
        )
