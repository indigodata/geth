import os
import smtplib
from email.message import EmailMessage

email_from = os.environ['FROM']
email_to = os.environ['FROM']
email_pwd = os.environ['PASSWORD']

msg = EmailMessage()
msg['From'] = email_from
msg['To'] = email_to
msg['Subject'] = 'Test From Local Python'
msg.set_content('This is a test email sent from a Python script.')

with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
    smtp.login(email_from, email_pwd)
    smtp.send_message(msg)
