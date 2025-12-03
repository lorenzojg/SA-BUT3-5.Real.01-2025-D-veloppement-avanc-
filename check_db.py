import sqlite3
import json
import os

db_path = 'assets/database/serenola.db'

if not os.path.exists(db_path):
    print(f"Error: Database file not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check destinations count
    cursor.execute("SELECT COUNT(*) FROM destinations")
    count = cursor.fetchone()[0]
    print(f"Total destinations: {count}")

    if count == 0:
        print("Database is empty!")
        exit(0)

    # Check monthlyFlightPrices
    cursor.execute("SELECT COUNT(*) FROM destinations WHERE monthlyFlightPrices IS NOT NULL AND monthlyFlightPrices != '[]'")
    flight_prices_count = cursor.fetchone()[0]
    print(f"Destinations with flight prices: {flight_prices_count}")

    # Check Milan specifically
    cursor.execute("SELECT name, monthlyFlightPrices, activities FROM destinations WHERE name = 'Milan'")
    milan = cursor.fetchone()
    if milan:
        print(f"\nMilan Data:\n- Flight Prices: {milan[1]}\n- Activities: {milan[2]}")

    # Check activities
    cursor.execute("SELECT name, activities FROM destinations LIMIT 5")
    rows = cursor.fetchall()
    print("\nSample activities:")
    for row in rows:
        name = row[0]
        activities = row[1]
        activity_list = activities.split(',')
        print(f"- {name}: {len(activity_list)} activities ({activities[:50]}...)")

    # Check average activity count
    cursor.execute("SELECT activities FROM destinations")
    all_activities = cursor.fetchall()
    total_activities = sum(len(row[0].split(',')) for row in all_activities)
    avg_activities = total_activities / count
    print(f"\nAverage activities per destination: {avg_activities:.1f}")

    conn.close()

except sqlite3.Error as e:
    print(f"SQLite error: {e}")
except Exception as e:
    print(f"Error: {e}")
