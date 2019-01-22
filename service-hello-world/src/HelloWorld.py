from flask import Flask

app = Flask(__name__)


@app.route('/hello')
def static_file(path):
    return app.send_static_file('media/hello.html')
