import os
import smtplib

from email.message import EmailMessage
from prettytable import PrettyTable

from snowflake_service import SnowflakeDB
from environment import SNOWFLAKE_CONFIG, EMAIL_FROM, EMAIL_PASSWORD

def query_node_metrics():
    MetricDB = SnowflakeDB(SNOWFLAKE_CONFIG)
    query = """
    select
      NODE_ID
    , count_if(MSG_TIMESTAMP > sysdate() - interval '1 day') as current_msg_ct
    , count_if(MSG_TIMESTAMP between sysdate() - interval '2 day'
        and sysdate() - interval '1 day') as previous_msg_ct
    , (current_msg_ct - previous_msg_ct) / previous_msg_ct * 100 as pct_difference
    from KEYSTONE_OFFCHAIN.NETWORK_FEED
    where MSG_TIMESTAMP >= sysdate() - interval '2 day'
    group by 1
    order by 1
    """

    node_metrics = MetricDB.query(query)
    return node_metrics

def format_snowflake_response(snowflake_response) -> PrettyTable:
    table = PrettyTable()
    table.field_names = ["Node ID", "Current Msg Ct", "Previous Msg Ct", "Percent Difference"]

    for tuple_row in snowflake_response:
        table.add_row(list(tuple_row))
    
    return table

def send_email():
    node_metrics = query_node_metrics()
    metric_table = format_snowflake_response(node_metrics)
    print(metric_table)
    print(metric_table.get_formatted_string('html'))

    msg = EmailMessage()
    msg['From'] = EMAIL_FROM
    msg['To'] = EMAIL_FROM
    msg['Subject'] = 'Test From Local Python'
    msg.set_content(metric_table.get_formatted_string('html'), subtype='html')

    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
        smtp.login(EMAIL_FROM, EMAIL_PASSWORD)
        smtp.send_message(msg)

send_email()