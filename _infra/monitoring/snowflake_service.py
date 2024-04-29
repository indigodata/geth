import sys
import snowflake.connector

from typing import List, Tuple, Any


class SnowflakeDB:
    def __init__(self, snowflake_config):
        print('Connecting to Snowflake')
        self.conn = snowflake.connector.connect(
            user=snowflake_config['user'],
            password=snowflake_config['password'],
            account=snowflake_config['account'],
            role=snowflake_config['role'],
            warehouse=snowflake_config['warehouse'],
            database=snowflake_config['database']
        )
        self.cursor = self.conn.cursor()
        self.cursor.execute(f"USE SCHEMA {snowflake_config['schema']}")

    def insert(self, query: str, payload: List[Tuple]) -> None:
        payload_length = len(payload)
        print(f'Inserting {payload_length} rows into Snowflake')
        for i in range(0, payload_length, 1000):
            batch = payload[i:i+1000]

            try:
                self.cursor.executemany(query, batch)
            except Exception as e:
                print(f"Error occurred: {e}")

            self.conn.commit()

    def query(self, query: str,  params: dict = None) -> List[Tuple[Any, ...]]:
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            result = self.cursor.fetchall()
            return result
        except Exception as err:
            print(f'Error querying Snowflake: {err}')
            sys.exit(1)

    def close(self) -> None:
        self.cursor.close()
        self.conn.close()