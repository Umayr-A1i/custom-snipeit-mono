from flask import Flask
from app.routes import routes

# Create Flask app at module level (pytest requires this)
app = Flask(__name__)

# Register routes blueprint
app.register_blueprint(routes)

# Only run the server if this file is executed directly
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
