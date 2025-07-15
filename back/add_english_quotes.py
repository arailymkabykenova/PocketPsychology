#!/usr/bin/env python3
"""
Script to add English quotes to the database
"""

import sqlite3
from database import Database

def add_english_quotes():
    """Add English quotes to the database"""
    db = Database()
    
    # English quotes
    english_quotes = [
        ("Be the change you wish to see in the world", "Mahatma Gandhi", "motivation"),
        ("Every day is a new opportunity to become better", "Unknown", "motivation"),
        ("Happiness is not in always doing what you want, but in always wanting what you do", "Leo Tolstoy", "happiness"),
        ("The most important thing is not what happens to us, but how we react to it", "Epictetus", "relationships"),
        ("Success is the ability to go from one failure to another with no loss of enthusiasm", "Winston Churchill", "success"),
        ("The best way to predict the future is to create it", "Peter Drucker", "future"),
        ("You cannot control everything that happens to you, but you can control your reaction", "Unknown", "control"),
        ("Every experience, even negative, makes you stronger", "Unknown", "experience"),
        ("Belief in yourself is the first step to success", "Unknown", "belief"),
        ("Patience is not the ability to wait, but the ability to keep a good attitude while waiting", "Unknown", "patience"),
        ("The only way to do great work is to love what you do", "Steve Jobs", "passion"),
        ("Life is what happens when you're busy making other plans", "John Lennon", "life"),
        ("The future belongs to those who believe in the beauty of their dreams", "Eleanor Roosevelt", "dreams"),
        ("It does not matter how slowly you go as long as you do not stop", "Confucius", "perseverance"),
        ("The mind is everything. What you think you become", "Buddha", "mindset")
    ]
    
    with sqlite3.connect(db.db_path) as conn:
        cursor = conn.cursor()
        
        # Check if English quotes already exist
        cursor.execute('SELECT COUNT(*) FROM quotes WHERE language = "en"')
        count = cursor.fetchone()[0]
        
        if count == 0:
            # Insert English quotes
            cursor.executemany('''
                INSERT INTO quotes (text, author, topic, language, is_generated)
                VALUES (?, ?, ?, 'en', 0)
            ''', english_quotes)
            
            conn.commit()
            print(f"✅ Added {len(english_quotes)} English quotes to the database")
        else:
            print(f"ℹ️  English quotes already exist in the database ({count} quotes)")

if __name__ == "__main__":
    add_english_quotes() 