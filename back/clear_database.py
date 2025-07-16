#!/usr/bin/env python3
"""
Скрипт для полной очистки базы данных
Удаляет все данные, но сохраняет структуру таблиц
"""

import os
import sqlite3
from database import Database

def get_database_stats():
    """Получить статистику базы данных"""
    db = Database()
    conn = sqlite3.connect(db.db_path)
    cursor = conn.cursor()
    
    print("=== ТЕКУЩАЯ СТАТИСТИКА БАЗЫ ДАННЫХ ===")
    print(f"Файл БД: {db.db_path}")
    print(f"Размер файла: {os.path.getsize(db.db_path) / (1024*1024):.2f} MB")
    
    # Получить список таблиц
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    print("\n=== СОДЕРЖИМОЕ ТАБЛИЦ ===")
    total_records = 0
    for table in tables:
        table_name = table[0]
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"{table_name}: {count} записей")
        total_records += count
    
    print(f"\nВсего записей: {total_records}")
    conn.close()
    return total_records

def clear_database():
    """Очистить все данные из базы данных"""
    db = Database()
    conn = sqlite3.connect(db.db_path)
    cursor = conn.cursor()
    
    # Получить список таблиц (исключая системные)
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    print("\n=== ОЧИСТКА БАЗЫ ДАННЫХ ===")
    
    # Список таблиц для очистки (исключая системные)
    tables_to_clear = [
        'conversations',
        'topics', 
        'generated_content',
        'user_sessions',
        'quotes',
        'user_topics'
    ]
    
    total_deleted = 0
    for table_name in tables_to_clear:
        if table_name in [t[0] for t in tables]:
            cursor.execute(f"DELETE FROM {table_name}")
            deleted_count = cursor.rowcount
            print(f"Удалено из {table_name}: {deleted_count} записей")
            total_deleted += deleted_count
    
    # Сбросить автоинкрементные счетчики
    cursor.execute("DELETE FROM sqlite_sequence")
    print("Сброшены автоинкрементные счетчики")
    
    conn.commit()
    conn.close()
    
    print(f"\nВсего удалено записей: {total_deleted}")
    return total_deleted

def repopulate_default_data():
    """Заполнить базу данных дефолтными данными"""
    db = Database()
    
    print("\n=== ЗАПОЛНЕНИЕ ДЕФОЛТНЫМИ ДАННЫМИ ===")
    
    # Заполнить дефолтными цитатами
    db.populate_default_quotes()
    print("Добавлены дефолтные цитаты")
    
    # Можно добавить другие дефолтные данные здесь
    print("База данных готова к использованию")

def main():
    """Основная функция"""
    print("🧹 СКРИПТ ОЧИСТКИ БАЗЫ ДАННЫХ")
    print("=" * 50)
    
    # Показать текущую статистику
    total_records = get_database_stats()
    
    if total_records == 0:
        print("\n✅ База данных уже пуста!")
        return
    
    # Запросить подтверждение
    print(f"\n⚠️  ВНИМАНИЕ: Это действие удалит ВСЕ {total_records} записей из базы данных!")
    print("Это действие НЕОБРАТИМО!")
    
    confirm = input("\nВведите 'YES' для подтверждения очистки: ")
    
    if confirm != 'YES':
        print("❌ Очистка отменена")
        return
    
    # Выполнить очистку
    try:
        deleted_count = clear_database()
        
        # Показать результат
        print(f"\n✅ Успешно удалено {deleted_count} записей")
        
        # Заполнить дефолтными данными
        repopulate_default_data()
        
        # Показать новую статистику
        print("\n" + "=" * 50)
        get_database_stats()
        
        print("\n🎉 База данных успешно очищена и готова к использованию!")
        
    except Exception as e:
        print(f"\n❌ Ошибка при очистке базы данных: {e}")

if __name__ == "__main__":
    main() 