import logging
import smtplib

import pandas as pd

from datetime import datetime, timedelta
from email.message import EmailMessage

from premailer import transform
from snowflake_service import SnowflakeDB
from environment import (
    SNOWFLAKE_CONFIG, EMAIL_FROM, 
    EMAIL_TO_1, EMAIL_TO_2, EMAIL_PASSWORD)

def query_node_metrics() -> pd.DataFrame:
    MetricDB = SnowflakeDB(SNOWFLAKE_CONFIG)
    query = """
    SELECT
          node_id
        , COUNT_IF(msg_timestamp > SYSDATE() - INTERVAL '1 day')        AS current_msg_ct
        , COUNT_IF(msg_timestamp BETWEEN SYSDATE() - INTERVAL '2 day'
            AND SYSDATE() - INTERVAL '1 day')                           AS previous_msg_ct
        , ROUND(
            (current_msg_ct - previous_msg_ct) / previous_msg_ct * 100,
            2
          )                                                             AS pct_difference
    FROM keystone_offchain.network_feed
    WHERE msg_timestamp >= SYSDATE() - INTERVAL '2 day'
    GROUP BY 1
    ORDER BY 1
    """

    node_metrics = MetricDB.query(query=query, pandas=True)
    return node_metrics

def color_pct_difference(val):
    val_abs = abs(val)
    if val_abs > 50:
        color = 'red'
    elif val_abs > 30:
        color = 'orange'
    else:
        color = ''
    return f'background-color: {color}'

def format_numbers(value):
    if value >= 1000000:
        return f'{round(value / 1000000)}M'
    elif value >= 1000:
        return f'{round(value / 1000)}k'
    else:
        return str(value)
    
def format_table(df: pd.DataFrame) -> pd.DataFrame:
    df.index += 1
    df[['CURRENT_MSG_CT', 'PREVIOUS_MSG_CT']] = df[['CURRENT_MSG_CT', 'PREVIOUS_MSG_CT']].map(format_numbers)
    return df

def style_table(df: pd.DataFrame) -> pd.DataFrame:
    styled_df = df.style.map(color_pct_difference, subset=['PCT_DIFFERENCE'])
    html_table = styled_df.to_html()
    return html_table

def send_email() -> None:
    current_period = datetime.utcnow().strftime('%m-%d-%Y %H:%M:%S')
    previous_period = (datetime.utcnow() - timedelta(days=1)).strftime('%m-%d-%Y %H:%M:%S')

    node_metrics = query_node_metrics()
    formated_table = format_table(node_metrics)
    html_table = transform(style_table(formated_table), cssutils_logging_level=logging.FATAL)

    run_metadata = (
        f"<p>Observation periods are 24 hours, ending at the stated times below.<br>"
        f"Run Period: {current_period}<br>" # todo add hour 
        f"Previous Period: {previous_period}</p>" # todo add hour 
    )

    html_content = html_table + run_metadata
        
    msg = EmailMessage()
    msg['From'] = EMAIL_FROM
    msg['To'] = (EMAIL_TO_1, EMAIL_TO_2)
    msg['Subject'] = f"Network Feed Metrics {datetime.utcnow().strftime('%m-%d-%Y')}"
    msg.set_content(html_content, subtype='html')
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
        smtp.login(EMAIL_FROM, EMAIL_PASSWORD)
        smtp.send_message(msg)

if __name__ == '__main__':
    send_email()
