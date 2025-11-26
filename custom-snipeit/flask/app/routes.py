import os
import requests
from flask import Blueprint, jsonify, request
from app.oauth_client import oauth_client

routes = Blueprint("routes", __name__)

SNIPE_API_BASE = os.getenv("SNIPEIT_BASE_URL")  # same as APP_URL but used for /api

@routes.route("/health", methods=["GET"])
def health():
    return jsonify(status="ok"), 200

@routes.route("/asset/<asset_id>", methods=["GET"])
def get_asset(asset_id):
    token = oauth_client.get_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json"
    }
    url = f"{SNIPE_API_BASE}/api/v1/hardware/{asset_id}"
    r = requests.get(url, headers=headers)
    return jsonify(r.json()), r.status_code

@routes.route("/asset/<asset_id>", methods=["PUT"])
def update_asset(asset_id):
    token = oauth_client.get_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    url = f"{SNIPE_API_BASE}/api/v1/hardware/{asset_id}"
    r = requests.put(url, json=request.json, headers=headers)
    return jsonify(r.json()), r.status_code
