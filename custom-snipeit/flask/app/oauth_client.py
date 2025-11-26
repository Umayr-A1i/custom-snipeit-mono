import os
import time
import requests

class SnipeOAuthClient:
    def __init__(self):
        self.base_url = os.getenv("SNIPEIT_BASE_URL")      #env variables that will be configured in the EC2
        self.client_id = os.getenv("SNIPEIT_OAUTH_CLIENT_ID")
        self.client_secret = os.getenv("SNIPEIT_OAUTH_CLIENT_SECRET")
        self.token = None
        self.token_expiry = 0

    def _fetch_token(self):
        url = f"{self.base_url}/oauth/token"
        data = {
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "scope": "*"   
        }
        resp = requests.post(url, data=data)
        resp.raise_for_status()
        body = resp.json()
        self.token = body["access_token"]
        # expiry seconds is often 'expires_in'
        self.token_expiry = time.time() + body.get("expires_in", 3600) - 60

    def get_token(self):
        if not self.token or time.time() >= self.token_expiry:
            self._fetch_token()
        return self.token

oauth_client = SnipeOAuthClient()
