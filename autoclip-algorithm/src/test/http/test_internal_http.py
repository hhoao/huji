import json

from src.main.http.internal_http import InternalHttp
from src.test.base.test_base import TestCaseBase


class TestFileSystem(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_request(self):
        client = InternalHttp(self.config.internal.http)
        response = client.client.post(
            url="http://localhost:48080/admin-api/api/autoclip/success",
            content=json.dumps(
                {
                    "auto_clip_info": {
                        "file_info": {
                            "config_id": 1,
                            "path": "test.mp4",
                            "name": "test.mp4",
                            "type": "video/mp4",
                            "size": 1000,
                            "url": "http://localhost:48080/admin-api/api/autoclip/success",
                        }
                    }
                }
            ),
        )
        print(response.json())
