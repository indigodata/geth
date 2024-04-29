import os
from dotenv import dotenv_values

config = {
    **dotenv_values(".env"), # load variables from .env file
    **os.environ,  # override loaded values with environment variables
}

EMAIL_FROM = config.get('EMAIL_FROM')
EMAIL_TO_1 = config.get('EMAIL_TO_1')
EMAIL_TO_2 = config.get('EMAIL_TO_2')
EMAIL_PASSWORD = config.get('EMAIL_PASSWORD')

SNOWFLAKE_CONFIG = {
    'user': config.get('SNOWFLAKE_USER'),
    'password': config.get('SNOWFLAKE_PASSWORD'),
    'account': config.get('SNOWFLAKE_ACCOUNT'),
    'role': config.get('SNOWFLAKE_ROLE'),
    'warehouse': config.get('SNOWFLAKE_WAREHOUSE'),
    'database': config.get('SNOWFLAKE_DATABASE'),
    'schema': config.get('SNOWFLAKE_SCHEMA'),
}

SENTRY_DSN = config.get("SENTRY_DSN", "")