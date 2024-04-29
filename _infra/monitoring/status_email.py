import os
import smtplib

from typing import List
from email.message import EmailMessage
from prettytable import PrettyTable

from snowflake_service import SnowflakeDB
from environment import SNOWFLAKE_CONFIG, EMAIL_FROM, EMAIL_PASSWORD

def query_node_metrics() -> List[Tuple[Any, ...]]:
    MetricDB = SnowflakeDB(SNOWFLAKE_CONFIG)
    query = """
    SELECT
          node_id
        , COUNT_IF(msg_timestamp > SYSDATE() - INTERVAL '1 day')        AS current_msg_ct
        , COUNT_IF(msg_timestamp BETWEEN SYSDATE() - INTERVAL '2 day'
            AND SYSDATE() - INTERVAL '1 day')                           AS previous_msg_ct
        , (current_msg_ct - previous_msg_ct) / previous_msg_ct * 100    AS pct_difference
    FROM keystone_offchain.network_feed
    WHERE msg_timestamp >= SYSDATE() - INTERVAL '2 day'
    GROUP BY 1
    ORDER BY 1
    """

    node_metrics = MetricDB.query(query)
    return node_metrics

def format_snowflake_response(snowflake_response) -> PrettyTable:
    table = PrettyTable()
    table.field_names = ["Node ID", "Current Msg Ct", "Previous Msg Ct", "Percent Difference"]

    for tuple_row in snowflake_response:
        table.add_row(list(tuple_row))
    
    return table

def send_email() -> None:
    node_metrics = query_node_metrics()
    metric_table = format_snowflake_response(node_metrics)
    
    html_table = f"""
    <html>
    <body>
    <pre>
    {metric_table.get_string()}
    </pre>
    </body>
    </html>
    """

    msg = EmailMessage()
    msg['From'] = EMAIL_FROM
    msg['To'] = EMAIL_FROM
    msg['Subject'] = 'Test From Local Python'
    msg.set_content(html_table, subtype='html')
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
        smtp.login(EMAIL_FROM, EMAIL_PASSWORD)
        smtp.send_message(msg)

send_email()