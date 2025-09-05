from flask import Flask, jsonify, request
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db_connection():
    """Establishes a connection to the database."""
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "db"),
        database=os.environ.get("DB_NAME", "micro_db"),
        user=os.environ.get("DB_USER", "micro_user"),
        password=os.environ.get("DB_PASSWORD", "micro_password")
    )
    return conn

def setup_database():
    """Creates the orders table if it doesn't exist."""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS orders (
                        id SERIAL PRIMARY KEY,
                        product_id INTEGER NOT NULL,
                        user_id INTEGER NOT NULL,
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                conn.commit()
    except psycopg2.Error as e:
        print(f"Database setup failed: {e}")
        # In a real application, you might want to exit or have a more robust retry mechanism.

@app.route('/')
def health_check():
    return jsonify({"status": "Order service is running"}), 200

@app.route('/orders', methods=['GET', 'POST'])
def handle_orders():
    try:
        with get_db_connection() as conn:
            # Using RealDictCursor makes the output a dictionary, which is easier to work with.
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                if request.method == 'GET':
                    cur.execute('SELECT id, product_id, user_id FROM orders;')
                    orders = cur.fetchall()
                    return jsonify(orders)

                elif request.method == 'POST':
                    new_order = request.get_json()
                    product_id = new_order.get('product_id')
                    user_id = new_order.get('user_id')

                    if not product_id or not user_id:
                        return jsonify({"error": "Missing product_id or user_id"}), 400

                    cur.execute('INSERT INTO orders (product_id, user_id) VALUES (%s, %s) RETURNING id, product_id, user_id;', (product_id, user_id))
                    created_order = cur.fetchone()
                    conn.commit()
                    return jsonify(created_order), 201
    except (psycopg2.Error, AttributeError) as e:
        # General error handling for database issues or if request.get_json() fails.
        return jsonify({"error": "An internal error occurred.", "details": str(e)}), 500

if __name__ == "__main__":
    setup_database()
    app.run(host='0.0.0.0', port=5003)